/***************************************************************************
 *   Copyright 2022 Paul Bergmann                                          *
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

#include "udpmulticaster.h"

#include <QByteArray>
#include <QHostAddress>
#include <QNetworkInterface>
#include <QUdpSocket>
#include <QtGlobal>
#include <vector>
#include <QDebug>

UDPMulticaster::UDPMulticaster(const QHostAddress& address, quint16 port, QObject* parent)
{
    for (const QNetworkInterface& interface : QNetworkInterface::allInterfaces()) {
        if (!(interface.flags() & QNetworkInterface::CanMulticast)) {
            continue;
        }

        QUdpSocket* socket = new QUdpSocket(parent);
        socket->connectToHost(address, port, QUdpSocket::WriteOnly);
        socket->setMulticastInterface(interface);

        m_sockets.push_back(socket);
    }
}

void UDPMulticaster::send(const QByteArray& data)
{
    for (QUdpSocket* socket : m_sockets) {
        if (socket->write(data) < 0) {
            qWarning() << "Could not send data: " << socket->errorString();
        }
    }
}

