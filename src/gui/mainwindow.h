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

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include "amun/amunclient.h"
#include "protobuf/robot.pb.h"
#include <QMainWindow>
#include <QSet>

class BallSpeedPlotter;
class InfoBoard;
class ConfigDialog;
class LogFileWriter;
class RefereeStatusWidget;
class QLabel;
class QModelIndex;
class QThread;
namespace Ui {
    class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(bool showInfoboard, QWidget *parent = 0);
    ~MainWindow() override;

signals:
    void gotStatus(const Status &status);

protected:
    void closeEvent(QCloseEvent *e) override;

private slots:
    void handleStatus(const Status &status);
    void sendCommand(const Command &command);
    void setRecording(bool record);
    void showConfigDialog();
    void setFlipped(bool flipped);

private:
    Ui::MainWindow *ui;
    BallSpeedPlotter *m_plotter;
    InfoBoard *m_infoboard;
    AmunClient m_amun;
    RefereeStatusWidget *m_refereeStatus;
    ConfigDialog *m_configDialog;

    LogFileWriter *m_logFile;
    QThread *m_logFileThread;
    qint64 m_lastTime;
    QLabel *m_logTimeLabel;
    qint64 m_logStartTime;
    robot::Team m_yellowTeam;
    robot::Team m_blueTeam;
    QString m_yellowTeamName;
    QString m_blueTeamName;
};

#endif // MAINWINDOW_H
