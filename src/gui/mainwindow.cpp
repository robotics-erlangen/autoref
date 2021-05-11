/***************************************************************************
 *   Copyright 2015 Michael Eischer, Philipp Nordhus, Alexander Danzer     *
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

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "ballspeedplotter.h"
#include "configdialog.h"
#include "core/timer.h"
#include "infoboard.h"
#include "seshat/logfilewriter.h"
#include "robotselectionwidget.h"
#include "widgets/refereestatuswidget.h"
#include <QDateTime>
#include <QFile>
#include <QFileDialog>
#include <QLabel>
#include <QMetaType>
#include <QThread>

MainWindow::MainWindow(bool showInfoboard, QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow),
    m_logFile(NULL),
    m_logFileThread(NULL),
    m_logStartTime(0)
{
    qRegisterMetaType<SSL_Referee::Command>("SSL_Referee::Command");
    qRegisterMetaType<SSL_Referee::Stage>("SSL_Referee::Stage");

    setWindowIcon(QIcon("icon:autoref.svg"));
    ui->setupUi(this);

    // setup icons
    ui->actionSidesFlipped->setIcon(QIcon("icon:32/change-ends.png"));
    ui->actionRecord->setIcon(QIcon("icon:32/media-record.png"));
    ui->actionConfiguration->setIcon(QIcon("icon:32/preferences-system.png"));

    ui->actionQuit->setShortcut(QKeySequence::Quit);

    // setup status bar
    m_logTimeLabel = new QLabel();
    statusBar()->addPermanentWidget(m_logTimeLabel);
    m_logTimeLabel->hide();

    m_refereeStatus = new RefereeStatusWidget;
    statusBar()->addPermanentWidget(m_refereeStatus);

    // setup ui parts that send commands
    connect(ui->autoref, SIGNAL(sendCommand(Command)), SLOT(sendCommand(Command)));
    ui->autoref->init();

    connect(ui->field, SIGNAL(sendCommand(Command)), SLOT(sendCommand(Command)));
    ui->field->hideVisualizationToggles();

    m_configDialog = new ConfigDialog(this);
    connect(m_configDialog, SIGNAL(sendCommand(Command)), SLOT(sendCommand(Command)));
    if (m_configDialog->plotterInExtraWindow()) {
        m_plotter = new BallSpeedPlotter(nullptr);
    } else {
        m_plotter = new BallSpeedPlotter(this);
        ui->splitterTop->addWidget(m_plotter);
    }
    m_plotter->show();

    connect(ui->options, SIGNAL(sendCommand(Command)), SLOT(sendCommand(Command)));

    m_infoboard = new InfoBoard();
    if (showInfoboard) {
        m_infoboard->show();
    }

    // setup visualization only parts of the ui
    connect(ui->visualization, SIGNAL(itemsChanged(QStringList)), ui->field, SLOT(visualizationsChanged(QStringList)));
    connect(ui->visualization, SIGNAL(itemsChanged(QStringList)), m_infoboard->field, SLOT(visualizationsChanged(QStringList)));

    ui->log->hideLogToggles();

    // connect the menu actions
    connect(ui->actionSidesFlipped, SIGNAL(toggled(bool)), SLOT(setFlipped(bool)));
    connect(ui->actionConfiguration, SIGNAL(triggered()), SLOT(showConfigDialog()));
    connect(ui->actionRecord, SIGNAL(toggled(bool)), SLOT(setRecording(bool)));
    connect(ui->actionShowOptions, &QAction::triggered, [=]() {
            ui->dockOptions->setVisible(!ui->dockOptions->isVisible());
    });

    // setup data distribution
    connect(this, SIGNAL(gotStatus(Status)), ui->field, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), m_plotter, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), m_infoboard, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), m_infoboard->field, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), ui->visualization, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), ui->debugTree, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), ui->timing, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), m_refereeStatus, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), ui->log, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), ui->autoref, SLOT(handleStatus(Status)));
    connect(this, SIGNAL(gotStatus(Status)), ui->options, SLOT(handleStatus(Status)));

    // start amun
    connect(&m_amun, SIGNAL(gotStatus(Status)), SLOT(handleStatus(Status)));
    m_amun.start();

    // restore configuration and initialize everything
    ui->autoref->load();
    ui->visualization->load();
    m_configDialog->load();

    // hide dock widgets by default
    ui->dockAutoref->hide();
    ui->dockVisualization->hide();
    ui->dockTiming->hide();

    ui->splitterV->setSizes({(int)(size().height()*0.3), (int)(size().height()*0.7)});
    ui->splitterTop->setSizes({(int)(size().width()*0.25), (int)(size().width()*0.75)});
    ui->splitterBottom->setSizes({(int)(size().width()*0.4), (int)(size().width()*0.6)});

    // disable internal referee
    Command command(new amun::Command);
    amun::CommandReferee *referee = command->mutable_referee();
    referee->set_active(false);
    sendCommand(command);
    // force auto reload of strategies if external referee is used
    ui->autoref->forceAutoReload(true);
}

MainWindow::~MainWindow()
{
    if (m_logFileThread) {
        m_logFileThread->quit();
        m_logFileThread->wait();
        delete m_logFileThread;
    }
    delete m_logFile;
    delete m_plotter;
    delete m_infoboard;
    delete ui;
}

void MainWindow::closeEvent(QCloseEvent *e)
{
    // make sure the plotter is closed along with the mainwindow
    // this also ensure that a closeEvent is triggered
    m_plotter->close();
    m_infoboard->close();

    ui->autoref->shutdown();

    QMainWindow::closeEvent(e);
}

void MainWindow::handleStatus(const Status &status)
{
    // keep team names for the logfile
    if (status->has_game_state()) {
        const amun::GameState &state = status->game_state();

        const SSL_Referee_TeamInfo &teamBlue = state.blue();
        m_blueTeamName = QString::fromStdString(teamBlue.name());

        const SSL_Referee_TeamInfo &teamYellow = state.yellow();
        m_yellowTeamName = QString::fromStdString(teamYellow.name());

        if (state.has_goals_flipped()) {
            ui->actionSidesFlipped->setChecked(state.goals_flipped());
        }
    }

    // keep team configurations for the logfile
    if (status->has_team_yellow()) {
        m_yellowTeam.CopyFrom(status->team_yellow());
    }
    if (status->has_team_blue()) {
        m_blueTeam.CopyFrom(status->team_blue());
    }
    m_lastTime = status->time();

    if (m_logStartTime != 0) {
        qint64 timeDelta = m_lastTime - m_logStartTime;
        const double dtime = timeDelta / 1E9;
        QString logLabel = "Log time: " + QString("%1:%2").arg((int) dtime / 60)
                .arg((int) dtime % 60, 2, 10, QChar('0'));
        if (m_logTimeLabel->text() != logLabel) {
            m_logTimeLabel->setText(logLabel);
        }
    }

    if (status->has_amun_state() && status->amun_state().has_port_bind_error()) {
        QLabel *label = new QLabel(this);
        label->setText("<font color=\"red\">Failed to bind the vision port. Ra must be started BEFORE ssl-vision if it runs locally!</font>");
        statusBar()->addPermanentWidget(label);
    }

    emit gotStatus(status);
}

void MainWindow::sendCommand(const Command &command)
{
    m_amun.sendCommand(command);
}

void MainWindow::setFlipped(bool flipped)
{
    Command command(new amun::Command);
    amun::CommandReferee *referee = command->mutable_referee();
    referee->set_flipped(flipped);
    sendCommand(command);
}

static QString toString(const QDateTime& dt)
{
    const int utcOffset = dt.secsTo(QDateTime(dt.date(), dt.time(), Qt::UTC));

    int sign = utcOffset >= 0 ? 1: -1;
    const QString date = dt.toString(Qt::ISODate) + QString::fromLatin1("%1%2%3")
            .arg(sign == 1 ? QLatin1Char('+') : QLatin1Char('-'))
            .arg(utcOffset * sign / (60 * 60), 2, 10, QLatin1Char('0'))
            .arg((utcOffset / 60) % 60, 2, 10, QLatin1Char('0'));
    return date;
}

void MainWindow::setRecording(bool record)
{
    if (record) {
        Q_ASSERT(!m_logFile);

        QString teamnames;
        if (!m_yellowTeamName.isEmpty() && !m_blueTeamName.isEmpty()) {
            teamnames = QString("%1 vs %2").arg(m_yellowTeamName).arg(m_blueTeamName);
        } else if (!m_yellowTeamName.isEmpty()) {
            teamnames = m_yellowTeamName;
        } else  if (!m_blueTeamName.isEmpty()) {
            teamnames = m_blueTeamName;
        }

        const QString date = toString(QDateTime::currentDateTime()).replace(":", "");
        const QString filename = QString("%1%2.log").arg(date).arg(teamnames);

        // create log file and forward status
        m_logFile = new LogFileWriter();
        if (!m_logFile->open(filename)) {
            ui->actionRecord->setChecked(false);
            delete m_logFile;
            return;
        }
        connect(this, SIGNAL(gotStatus(Status)), m_logFile, SLOT(writeStatus(Status)));

        // create thread if not done yet and move to seperate thread
        if (m_logFileThread == NULL) {
            m_logFileThread = new QThread();
            m_logFileThread->start();
        }
        m_logFile->moveToThread(m_logFileThread);

        // add the current team settings to the logfile
        Status status(new amun::Status);
        status->set_time(m_lastTime);
        status->mutable_team_yellow()->CopyFrom(m_yellowTeam);
        status->mutable_team_blue()->CopyFrom(m_blueTeam);
        m_logFile->writeStatus(status);
        m_logStartTime = m_lastTime;
        m_logTimeLabel->show();
    } else {
        // defer log file deletion to happen in its thread
        m_logFile->deleteLater();
        m_logFile = NULL;
        m_logStartTime = 0;
        m_logTimeLabel->setText("");
        m_logTimeLabel->hide();
    }
}

void MainWindow::showConfigDialog()
{
    m_configDialog->exec();
}
