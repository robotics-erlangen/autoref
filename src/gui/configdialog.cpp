/***************************************************************************
 *   Copyright 2015 Michael Bleier, Michael Eischer, Philipp Nordhus       *
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

#include "configdialog.h"
#include "ui_configdialog.h"
#include "core/sslprotocols.h"
#include <QPushButton>
#include <QSettings>

const uint DEFAULT_VISION_TRANSMISSION_DELAY = 0; // in ms
const uint DEFAULT_VISION_PORT = SSL_VISION_PORT;
const uint DEFAULT_REFEREE_PORT = SSL_GAME_CONTROLLER_PORT;
const uint DEFAULT_VISION_TRACKER_PORT = SSL_VISION_TRACKER_PORT;

const bool DEFAULT_PLOTTER_IN_EXTRA_WINDOW = false;

ConfigDialog::ConfigDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::ConfigDialog)
{
    ui->setupUi(this);
    connect(ui->buttonBox, SIGNAL(clicked(QAbstractButton*)), SLOT(clicked(QAbstractButton*)));
    connect(this, SIGNAL(rejected()), SLOT(load()));
}

ConfigDialog::~ConfigDialog()
{
    delete ui;
}

void ConfigDialog::sendConfiguration()
{
    Command command(new amun::Command);
    // from ms to ns
    command->mutable_tracking()->set_vision_transmission_delay(ui->visionTransmissionDelayBox->value() * 1000 * 1000);

    command->mutable_amun()->set_vision_port(ui->visionPort->value());
    command->mutable_amun()->set_referee_port(ui->refPort->value());
    command->mutable_amun()->set_tracker_port(ui->trackerPort->value());

    emit sendCommand(command);
}

void ConfigDialog::load()
{
    QSettings s;
    ui->visionTransmissionDelayBox->setValue(s.value("Tracking/VisionTransmissionDelayAutoref", DEFAULT_VISION_TRANSMISSION_DELAY).toUInt()); // in ms

    ui->visionPort->setValue(s.value("Amun/VisionPort2018", DEFAULT_VISION_PORT).toUInt());
    ui->refPort->setValue(s.value("Amun/RefereePort", DEFAULT_REFEREE_PORT).toUInt());
    ui->trackerPort->setValue(s.value("Amun/TrackerPort", DEFAULT_VISION_TRACKER_PORT).toUInt());

    ui->plotterInExtraWindow->setChecked(s.value("Amun/PlotterInExtraWindow", DEFAULT_PLOTTER_IN_EXTRA_WINDOW).toBool());

    sendConfiguration();
}

void ConfigDialog::reset()
{
    ui->visionTransmissionDelayBox->setValue(DEFAULT_VISION_TRANSMISSION_DELAY);
    ui->visionPort->setValue(DEFAULT_VISION_PORT);
    ui->refPort->setValue(DEFAULT_REFEREE_PORT);
    ui->trackerPort->setValue(DEFAULT_VISION_TRACKER_PORT);
    ui->plotterInExtraWindow->setChecked(DEFAULT_PLOTTER_IN_EXTRA_WINDOW);
}

void ConfigDialog::apply()
{
    QSettings s;
    s.setValue("Tracking/VisionTransmissionDelayAutoref", ui->visionTransmissionDelayBox->value());

    s.setValue("Amun/VisionPort2018", ui->visionPort->value());
    s.setValue("Amun/RefereePort", ui->refPort->value());
    s.setValue("Amun/TrackerPort", ui->trackerPort->value());

    s.setValue("Amun/PlotterInExtraWindow", ui->plotterInExtraWindow->isChecked());

    sendConfiguration();
}

void ConfigDialog::clicked(QAbstractButton *button)
{
    switch (ui->buttonBox->buttonRole(button)) {
    case QDialogButtonBox::AcceptRole:
        apply();
        break;
    case QDialogButtonBox::ResetRole:
        reset();
        break;
    case QDialogButtonBox::RejectRole:
        load();
        break;
    default:
        break;
    }
}

bool ConfigDialog::plotterInExtraWindow()
{
    QSettings s;
    return s.value("Amun/PlotterInExtraWindow", DEFAULT_PLOTTER_IN_EXTRA_WINDOW).toBool();
}
