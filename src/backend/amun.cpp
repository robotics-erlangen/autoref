/***************************************************************************
 *   Copyright 2016 Michael Eischer, Philipp Nordhus                       *
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
#include "optionsmanager.h"
#include "core/timer.h"
#include "core/sslprotocols.h"
#include "processor/processor.h"
#include "strategy/strategy.h"
#include "networkinterfacewatcher.h"
#include "visiontrackedpublisher.h"
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
 * \brief Creates an Amun instance
 * \param parent Parent object
 */
Amun::Amun(bool simulatorOnly, QObject *parent) :
    QObject(parent)
{
    qRegisterMetaType<QNetworkInterface>("QNetworkInterface");
    qRegisterMetaType<Command>("Command");
    qRegisterMetaType< QList<robot::RadioCommand> >("QList<robot::RadioCommand>");
    qRegisterMetaType< QList<robot::RadioResponse> >("QList<robot::RadioResponse>");
    qRegisterMetaType<Status>("Status");
    qRegisterMetaType<amun::CommandReferee>("amun::CommandReferee");

    // global timer, which can be slowed down / sped up
    m_timer = new Timer;
    // these threads just run an event loop
    // using the signal-slot mechanism the objects in these can be called
    m_processorThread = new QThread(this);
    m_networkThread = new QThread(this);
    m_autorefThread = new QThread(this);

    m_networkInterfaceWatcher = new NetworkInterfaceWatcher(this);
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
    Q_ASSERT(m_processor == nullptr);
    m_processor = new Processor(m_timer, false);
    m_processor->moveToThread(m_processorThread);
    connect(m_processorThread, SIGNAL(finished()), m_processor, SLOT(deleteLater()));
    // route commands to processor
    connect(this, SIGNAL(gotCommand(Command)), m_processor, SLOT(handleCommand(Command)));
    // relay tracking, geometry, referee, controller and accelerator information
    connect(m_processor, SIGNAL(sendStatus(Status)), SLOT(handleStatus(Status)));

    m_optionsManager = new OptionsManager;
    m_optionsManager->moveToThread(thread());
    connect(this, &Amun::gotCommand, m_optionsManager, &OptionsManager::handleCommand);
    connect(m_optionsManager, &OptionsManager::sendStatus, this, &Amun::handleStatus);

    m_gameControllerConnection.reset(new GameControllerConnection(true));
    m_gameControllerConnection->switchInternalGameController(false);
    m_gameControllerConnection->moveToThread(m_autorefThread);
    connect(this, &Amun::gotRefereeHost, m_gameControllerConnection.get(), &GameControllerConnection::handleRefereeHost);

    // start strategy threads
    Q_ASSERT(m_autoref == nullptr);
    m_autoref = new Strategy(m_timer, StrategyType::AUTOREF, nullptr, nullptr, m_gameControllerConnection, false);
    m_autoref->moveToThread(m_autorefThread);
    connect(m_autorefThread, SIGNAL(finished()), m_autoref, SLOT(deleteLater()));


    // send tracking, geometry and referee to strategy
    connect(m_processor, SIGNAL(sendStrategyStatus(Status)),
            m_autoref, SLOT(handleStatus(Status)));
    connect(m_optionsManager, &OptionsManager::sendStatus, m_autoref, &Strategy::handleStatus);
    // route commands from and to strategy
    connect(m_autoref, SIGNAL(gotCommand(Command)), SLOT(handleCommand(Command)));
    connect(this, SIGNAL(gotCommand(Command)),
            m_autoref, SLOT(handleCommand(Command)));
    // relay status and debug information of strategy
    connect(m_autoref, SIGNAL(sendStatus(Status)), SLOT(handleStatus(Status)));
    connect(m_autoref, &Strategy::sendStatus, m_optionsManager, &OptionsManager::handleStatus);
    connect(m_processor, SIGNAL(setFlipped(bool)), m_autoref, SLOT(setFlipped(bool)));
    m_autoref->setFlipped(m_processor->getIsFlipped());

    // create referee
    setupReceiver(m_referee, QHostAddress(SSL_GAME_CONTROLLER_ADDRESS), SSL_GAME_CONTROLLER_PORT);
    connect(this, &Amun::updateRefereePort, m_referee, &Receiver::updatePort);
    // move referee packets to processor
    connect(m_referee, SIGNAL(gotPacket(QByteArray, qint64, QString)), m_processor, SLOT(handleRefereePacket(QByteArray, qint64)));
    connect(m_referee, SIGNAL(gotPacket(QByteArray,qint64,QString)), SLOT(handleRefereePacket(QByteArray,qint64,QString)));

    // create vision
    setupReceiver(m_vision, QHostAddress(SSL_VISION_ADDRESS), SSL_VISION_PORT);
    // allow updating the port used to listen for ssl vision
    connect(this, &Amun::updateVisionPort, m_vision, &Receiver::updatePort);
    // connect
    connect(m_vision, SIGNAL(gotPacket(QByteArray, qint64, QString)),
            m_processor, SLOT(handleVisionPacket(QByteArray, qint64, QString)));
    connect(m_vision, &Receiver::sendStatus, this, &Amun::handleStatus);

    m_visionPublisher = new VisionTrackedPublisher();
    m_visionPublisher->moveToThread(m_networkThread);
    connect(m_networkThread, SIGNAL(finished()), m_visionPublisher, SLOT(deleteLater()));
    connect(m_processor, &Processor::setFlipped, m_visionPublisher, &VisionTrackedPublisher::setFlip);
    connect(this, &Amun::sendStatus, m_visionPublisher, &VisionTrackedPublisher::handleStatus);

    // start threads
    m_processorThread->start();
    m_networkThread->start();
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
    m_autorefThread->quit();

    // wait for threads
    m_processorThread->wait();
    m_networkThread->wait();
    m_autorefThread->wait();

    delete m_optionsManager;

    // worker objects are destroyed on thread shutdown
    m_vision = nullptr;
    m_referee = nullptr;
    m_autoref = nullptr;
    m_processor = nullptr;
    m_optionsManager = nullptr;
    m_visionPublisher = nullptr;
}

void Amun::handleRefereePacket(QByteArray, qint64, QString host)
{
    emit gotRefereeHost(host);
}

void Amun::setupReceiver(Receiver *&receiver, const QHostAddress &address, quint16 port)
{
    Q_ASSERT(receiver == nullptr);
    receiver = new Receiver(address, port, m_timer);
    receiver->moveToThread(m_networkThread);
    connect(m_networkThread, SIGNAL(finished()), receiver, SLOT(deleteLater()));
    // start and stop socket
    connect(m_networkThread, SIGNAL(started()), receiver, SLOT(startListen()));
    // pass packets to processor
    connect(m_networkInterfaceWatcher, &NetworkInterfaceWatcher::interfaceUpdated, receiver, &Receiver::updateInterface);
}

/*!
 * \brief Process a command
 * \param command Command to process
 */
void Amun::handleCommand(const Command &command)
{
    if (command->has_amun()) {
        if (command->amun().has_vision_port()) {
            emit updateVisionPort(command->amun().vision_port());
        }
        if (command->amun().has_referee_port()) {
            emit updateRefereePort(command->amun().referee_port());
        }
    }

    emit gotCommand(command);
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
