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

const uint DEFAULT_SYSTEM_DELAY = 0; // in ms
const uint DEFAULT_VISION_PORT = 10005;
const bool DEFAULT_ENABLE_REFBOX_CONTROL = true;
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
    command->mutable_tracking()->set_system_delay(ui->systemDelayBox->value() * 1000 * 1000);

    command->mutable_amun()->set_vision_port(ui->visionPort->value());

    command->mutable_strategy_autoref()->set_enable_refbox_control(ui->refboxControlUse->isChecked());

    emit sendCommand(command);
}

void ConfigDialog::load()
{
    QSettings s;
    ui->systemDelayBox->setValue(s.value("Tracking/SystemDelayAutoref", DEFAULT_SYSTEM_DELAY).toUInt()); // in ms

    ui->visionPort->setValue(s.value("Amun/VisionPort", DEFAULT_VISION_PORT).toUInt());
    ui->refboxControlUse->setChecked(s.value("Amun/EnableRefboxControl", DEFAULT_ENABLE_REFBOX_CONTROL).toBool());
    ui->plotterInExtraWindow->setChecked(s.value("Amun/PlotterInExtraWindow", DEFAULT_PLOTTER_IN_EXTRA_WINDOW).toBool());

    sendConfiguration();
}

void ConfigDialog::reset()
{
    ui->systemDelayBox->setValue(DEFAULT_SYSTEM_DELAY);
    ui->visionPort->setValue(DEFAULT_VISION_PORT);
    ui->refboxControlUse->setChecked(DEFAULT_ENABLE_REFBOX_CONTROL);
    ui->plotterInExtraWindow->setChecked(DEFAULT_PLOTTER_IN_EXTRA_WINDOW);
}

void ConfigDialog::apply()
{
    QSettings s;
    s.setValue("Tracking/SystemDelayAutoref", ui->systemDelayBox->value());

    s.setValue("Amun/VisionPort", ui->visionPort->value());
    s.setValue("Amun/EnableRefboxControl", ui->refboxControlUse->isChecked());
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
