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
#include <QPushButton>
#include <QSettings>

const uint DEFAULT_SYSTEM_DELAY = 30; // in ms
const uint DEFAULT_VISION_PORT = 10002;

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
    command->mutable_tracking()->set_system_delay(ui->systemDelayBox->value() * 1000 * 1000);

    command->mutable_amun()->set_vision_port(ui->visionPort->value());
    emit sendCommand(command);
}

void ConfigDialog::load()
{
    QSettings s;
    ui->systemDelayBox->setValue(s.value("Tracking/SystemDelay", DEFAULT_SYSTEM_DELAY).toUInt()); // in ms

    ui->visionPort->setValue(s.value("Amun/VisionPort", DEFAULT_VISION_PORT).toUInt());
    sendConfiguration();
}

void ConfigDialog::reset()
{
    ui->systemDelayBox->setValue(DEFAULT_SYSTEM_DELAY);
    ui->visionPort->setValue(DEFAULT_VISION_PORT);
}

void ConfigDialog::apply()
{
    QSettings s;
    s.setValue("Tracking/SystemDelay", ui->systemDelayBox->value());

    s.setValue("Amun/VisionPort", ui->visionPort->value());

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
