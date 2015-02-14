/***************************************************************************
 *   Copyright 2015 Michael Eischer, Philipp Nordhus                       *
 *   Robotics Erlangen e.V.                                                *
 *   http://www.robotics-erlangen.de/                                      *
 *   info@robotics-erlangen.de                                             *
 *                                                                         *
 *   This program is free software: you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation, either version 3 of the License, or     *
 *   any later version.                                                    *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ***************************************************************************/

#include "amun.h"
#include "receiver.h"
#include "core/timer.h"
#include "processor/processor.h"
#include "simulator/simulator.h"
#include "strategy/strategy.h"
#include <QMetaType>
#include <QThread>

/*!
 * \class Amun
 * \ingroup amun
 * \brief Core class of Amun architecture
 *
 * Creates a processor thread, a simulator thread, a networking thread and two
 * strategy threads.
 */

/*!
 * \fn void Amun::gotCommand(const Command &command)
 * \brief Passes a \ref Command
 */

/*!
 * \fn void Amun::setScaling(float scaling)
 * \brief Passes scaling parameter
 */

/*!
 * \brief Creates an Amun instance
 * \param parent Parent object
 */
Amun::Amun(QObject *parent) :
    QObject(parent),
    m_processor(NULL),
    m_simulator(NULL),
    m_referee(NULL),
    m_vision(NULL),
    m_autoref(NULL),
    m_simulatorEnabled(false),
    m_scaling(1.0f),
    m_visionPort(10002)
{
    qRegisterMetaType<Command>("Command");
    qRegisterMetaType< QList<robot::RadioCommand> >("QList<robot::RadioCommand>");
    qRegisterMetaType< QList<robot::RadioResponse> >("QList<robot::RadioResponse>");
    qRegisterMetaType<Status>("Status");

    // global timer, which can be slowed down / sped up
    m_timer = new Timer;
    // these threads just run an event loop
    // using the signal-slot mechanism the objects in these can be called
    m_processorThread = new QThread(this);
    m_networkThread = new QThread(this);
    m_simulatorThread = new QThread(this);
    m_autorefThread = new QThread(this);
}

/*!
 * \brief Destroys the Amun instance
 */
Amun::~Amun()
{
    stop();
    delete m_timer;
}

/*!
 * \brief Start processing
 *
 * This method starts all threads.
 */
void Amun::start()
{
    // create processor
    Q_ASSERT(m_processor == NULL);
    m_processor = new Processor(m_timer);
    m_processor->moveToThread(m_processorThread);
    // route commands to processor
    connect(this, SIGNAL(gotCommand(Command)), m_processor, SLOT(handleCommand(Command)));
    // relay tracking, geometry, referee, controller and accelerator information
    connect(m_processor, SIGNAL(sendStatus(Status)), SLOT(handleStatus(Status)));
    // propagate time scaling
    connect(this, SIGNAL(setScaling(float)), m_processor, SLOT(setScaling(float)));

    // start strategy threads
    Q_ASSERT(m_autoref == NULL);
    m_autoref = new Strategy(m_timer, StrategyType::AUTOREF);
    m_autoref->moveToThread(m_autorefThread);

    // send tracking, geometry and referee to strategy
    connect(m_processor, SIGNAL(sendStrategyStatus(Status)),
            m_autoref, SLOT(handleStatus(Status)));
    // route commands from and to strategy
    connect(m_autoref, SIGNAL(gotCommand(Command)), SLOT(handleCommand(Command)));
    connect(this, SIGNAL(gotCommand(Command)),
            m_autoref, SLOT(handleCommand(Command)));
    // relay status and debug information of strategy
    connect(m_autoref, SIGNAL(sendStatus(Status)), SLOT(handleStatus(Status)));

    // create referee
    Q_ASSERT(m_referee == NULL);
    m_referee = new Receiver(QHostAddress("224.5.23.1"), 10003);
    m_referee->moveToThread(m_networkThread);
    // start and stop socket
    connect(m_networkThread, SIGNAL(started()), m_referee, SLOT(startListen()));
    connect(m_networkThread, SIGNAL(finished()), m_referee, SLOT(stopListen()));
    // move referee packets to processor
    connect(m_referee, SIGNAL(gotPacket(QByteArray, qint64)), m_processor, SLOT(handleRefereePacket(QByteArray, qint64)));

    // create vision
    Q_ASSERT(m_vision == NULL);
    m_vision = new Receiver(QHostAddress("224.5.23.2"), m_visionPort);
    m_vision->moveToThread(m_networkThread);
    connect(m_networkThread, SIGNAL(started()), m_vision, SLOT(startListen()));
    connect(m_networkThread, SIGNAL(finished()), m_vision, SLOT(stopListen()));
    // vision is connected in setSimulatorEnabled

    // create simulator
    Q_ASSERT(m_simulator == NULL);
    m_simulator = new Simulator(m_timer);
    m_simulator->moveToThread(m_simulatorThread);
    // pass on simulator and team settings
    connect(this, SIGNAL(gotCommand(Command)), m_simulator, SLOT(handleCommand(Command)));
    // pass simulator timing
    connect(m_simulator, SIGNAL(sendStatus(Status)), SLOT(handleStatus(Status)));
    // propagate time scaling
    connect(this, SIGNAL(setScaling(float)), m_simulator, SLOT(setScaling(float)));

    // connect simulator
    setSimulatorEnabled(false);

    // start threads
    m_processorThread->start();
    m_networkThread->start();
    m_simulatorThread->start();
    m_autorefThread->start();
}

/*!
 * \brief Stop processing
 *
 * All threads are stopped.
 */
void Amun::stop()
{
    // stop threads
    m_processorThread->quit();
    m_networkThread->quit();
    m_simulatorThread->quit();
    m_autorefThread->quit();

    // wait for threads
    m_processorThread->wait();
    m_networkThread->wait();
    m_simulatorThread->wait();
    m_autorefThread->wait();

    delete m_simulator;
    m_simulator = NULL;

    delete m_vision;
    m_vision = NULL;

    delete m_referee;
    m_referee = NULL;

    delete m_autoref;
    m_autoref = NULL;

    delete m_processor;
    m_processor = NULL;
}

void Amun::setVisionPort(quint16 port)
{
    m_visionPort = port;
}

/*!
 * \brief Process a command
 * \param command Command to process
 */
void Amun::handleCommand(const Command &command)
{
    if (command->has_simulator()) {
        if (command->simulator().has_enable()) {
            setSimulatorEnabled(command->simulator().enable());

            // time scaling can only be used with the simulator
            if (m_simulatorEnabled) {
                updateScaling(m_scaling);
            } else {
                // reset timer to realtime
                m_timer->reset();
                updateScaling(1.0);
            }
        }
    }

    if (command->has_speed()) {
        m_scaling = command->speed();
        if (m_simulatorEnabled) {
            updateScaling(m_scaling);
        }
    }

    emit gotCommand(command);
}

/*!
 * \brief Set time scaling and notify listeners of setScaling
 * \param scaling Scaling factor for time
 */
void Amun::updateScaling(float scaling)
{
    m_timer->setScaling(scaling);
    emit setScaling(scaling);
}

/*!
 * \brief Add timestamp and emit \ref sendStatus
 * \param status Status to send
 */
void Amun::handleStatus(const Status &status)
{
    status->set_time(m_timer->currentTime());
    emit sendStatus(status);
}

/*!
 * \brief Toggle simulator mode
 *
 * Switches vision input of \ref Processor to either SSLVision or
 * \ref Simulator.
 *
 * \param enabled Whether to enable or disable the simulator
 */
void Amun::setSimulatorEnabled(bool enabled)
{
    m_simulatorEnabled = enabled;
    // remove vision connections
    m_simulator->disconnect(m_processor);
    m_vision->disconnect(m_processor);

    if (enabled) {
        connect(m_simulator, SIGNAL(gotPacket(QByteArray, qint64)),
                m_processor, SLOT(handleVisionPacket(QByteArray,qint64)));
    } else {
        connect(m_vision, SIGNAL(gotPacket(QByteArray, qint64)),
                m_processor, SLOT(handleVisionPacket(QByteArray,qint64)));
    }
}
