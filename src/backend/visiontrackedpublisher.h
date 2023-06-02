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

#ifndef VISIONTRACKEDPUBLISHER_H
#define VISIONTRACKEDPUBLISHER_H

#include <QObject>
#include "gamecontroller/sslvisiontracked.h"
#include "protobuf/status.h"

#include "udpmulticaster.h"

class QUdpSocket;

class VisionTrackedPublisher : public QObject
{
public:
    VisionTrackedPublisher(QObject *parent = nullptr);

public slots:
    void setFlip(bool flip);
    void handleStatus(const Status &status);
    void updatePort(qint16 port);

private:
    SSLVisionTracked m_visionTracked;
    UDPMulticaster m_multicaster;
};

#endif // VISIONTRACKEDPUBLISHER_H
