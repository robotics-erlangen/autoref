/***************************************************************************
 *   Copyright 2021 Andreas Wendler                                        *
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

#include "visiontrackedpublisher.h"
#include <QHostAddress>
#include <QUdpSocket>

VisionTrackedPublisher::VisionTrackedPublisher(QObject *parent) :
    QObject(parent)
{
    m_senderSocket = new QUdpSocket(this);
}

void VisionTrackedPublisher::setFlip(bool flip)
{
    m_visionTracked.setFlip(flip);
}

void VisionTrackedPublisher::handleStatus(const Status &status)
{
    if (status->has_world_state()) {
        gameController::TrackerWrapperPacket packet;
        m_visionTracked.createTrackedFrame(status->world_state(), &packet);
        QByteArray data;
        data.resize(packet.ByteSize());
        if (packet.SerializeToArray(data.data(), data.size())) {
            m_senderSocket->writeDatagram(data, QHostAddress("224.5.23.2"), 10010);
        }
    }
}
