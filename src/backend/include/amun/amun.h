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

#ifndef AMUN_H
#define AMUN_H

#include "protobuf/command.h"
#include "protobuf/status.h"
#include <QObject>

class NetworkInterfaceWatcher;
class Processor;
class Receiver;
class Strategy;
class Timer;
class QHostAddress;

class Amun : public QObject
{
    Q_OBJECT

public:
    explicit Amun(bool simulatorOnly, QObject *parent = 0);
    ~Amun() override;

signals:
    void sendStatus(const Status &status);
    void gotCommand(const Command &command);
    void updateVisionPort(quint16 port);
    void updateRefereePort(quint16 port);
    void gotRefereeHost(QString hostName);

public:
    void start();
    void stop();

public slots:
    void handleCommand(const Command &command);
    void handleRefereePacket(QByteArray, qint64, QString host);

private slots:
    void handleStatus(const Status &status);

private:
    void setupReceiver(Receiver *&receiver, const QHostAddress &address, quint16 port);
    QThread *m_processorThread;
    QThread *m_networkThread;
    QThread *m_autorefThread;

    Processor *m_processor;
    Receiver *m_referee;
    Receiver *m_vision;
    Strategy *m_autoref;
    qint64 m_lastTime;
    Timer *m_timer;

    NetworkInterfaceWatcher *m_networkInterfaceWatcher;
};

#endif // AMUN_H
