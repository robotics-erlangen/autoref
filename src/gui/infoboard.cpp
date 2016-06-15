/***************************************************************************
 *   Copyright 2016 Alexander Danzer, Janine Schneider                     *
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

#include "infoboard.h"
#include "ui_infoboard.h"
#include "fieldwidget.h"
#include "protobuf/debug.pb.h"

InfoBoard::InfoBoard(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::InfoBoard),
    m_blinkCounter(1),
    m_blinkTimer(new QTimer),
    m_eventMsgTime(0),
    m_autorefMsgInvalidated(false)

{
    ui->setupUi(this);
    setWindowFlags(Qt::WindowStaysOnTopHint); // on ubuntu 14.04, this prevents the window frame
                                              // to show up when another window is active
    connect(m_blinkTimer, &QTimer::timeout, this, [this]{changeColor();});

    // HACK for private function call because we do not want to change the framework
    ui->fieldWidget->staticMetaObject.invokeMethod(ui->fieldWidget, "setVertical");
    field = ui->fieldWidget;

    setStyleSheet("background-color:white");

    ui->fieldWidget->setStyleSheet("border: 0px");

    ui->blueTeam->setTeamBlue();
    ui->blueTeam->setStyleSheet("background-color: #1E90FF; border-style:outset;"
                                "border-width:2px; border-radius:5px; border-color:grey");
    ui->yellowTeam->setStyleSheet("background-color: #FFFF00; border-style:outset;"
                                  "border-width:2px; border-radius:5px; border-color:grey");
    ui->gameStage->setTextFormat(Qt::RichText);
    ui->refState->setTextFormat(Qt::RichText);
    ui->time->setTextFormat(Qt::RichText);

    //game stages
    m_currentStage = "FIRST HALF<br>PREPARE";
    m_gameStagesDict.insert("NORMAL_FIRST_HALF_PRE", "FIRST HALF<br>PREPARE");
    m_gameStagesDict.insert("NORMAL_FIRST_HALF", "FIRST HALF");
    m_gameStagesDict.insert("NORMAL_HALF_TIME", "HALF TIME<br>BREAK");
    m_gameStagesDict.insert("NORMAL_SECOND_HALF_PRE", "SECOND HALF<br>PREPARE");
    m_gameStagesDict.insert("NORMAL_SECOND_HALF", "SECOND HALF");
    m_gameStagesDict.insert("EXTRA_TIME_BREAK", "EXTRA TIME<br>BREAK");
    m_gameStagesDict.insert("EXTRA_FIRST_HALF_PRE", "EXTRA TIME<br>FIRST HALF<br>PREPARE");
    m_gameStagesDict.insert("EXTRA_FIRST_HALF", "EXTRA TIME<br>FIRST HALF");
    m_gameStagesDict.insert("EXTRA_HALF_TIME", "EXTRA TIME<br>HALF TIME");
    m_gameStagesDict.insert("EXTRA_SECOND_HALF_PRE", "EXTRA TIME<br>SECOND HALF<br>PREPARE");
    m_gameStagesDict.insert("EXTRA_SECOND_HALF", "EXTRA TIME<br>SECOND HALF");
    m_gameStagesDict.insert("PENALTY_SHOOTOUT_BREAK", "PENALTY<br>SHOOTOUT<br>BREAK");
    m_gameStagesDict.insert("PENALTY_SHOOTOUT", "PENALTY<br>SHOOTOUT");
    m_gameStagesDict.insert("POST_GAME", "GAME OVER");
}

InfoBoard::~InfoBoard()
{
    delete ui;
}

void InfoBoard::resizeEvent(QResizeEvent *event)
{
    // unsetting the strings triggers font-size recalculation
    m_currentStage = "";
    m_refState = "";
}

void InfoBoard::updateGameStage(const amun::GameState &game_state)
{
    QString gameStageString = m_gameStagesDict[SSL_Referee::Stage_Name(game_state.stage())];

    if (gameStageString != m_currentStage) {
        int numLines = 0;
        int pos = 0;
        do { // count lines
            pos = gameStageString.toStdString().find("<br>", pos) + 1;
            numLines++;
        } while(pos > 0);
        QString styleDiv = QString("<div style=\"color: gray; font-size: %1px;\">")
                .arg((int)(ui->gameStage->height()/numLines/2.3));
        ui->gameStage->setText(styleDiv + gameStageString + QString("</div>"));
        m_currentStage = gameStageString;
    }
}

void InfoBoard::updateTime(const amun::GameState &game_state)
{
    const int timeRemaining = game_state.stage_time_left() / 1000000;

    ui->time->setText(QString("<div style=\"font-size: %1px;\">%2:%3</div>")
        .arg((int)(ui->gameStage->height()/2.2))
        .arg(timeRemaining / 60, 2, 10, QChar('0'))
        .arg(timeRemaining % 60, 2, 10, QChar('0')));
}

void InfoBoard::updateTeamScores(const amun::GameState &game_state)
{
    if (game_state.has_yellow()) {
        if (game_state.yellow().name().size() > 0) {
            ui->yellowTeam->setTeamName(QString::fromStdString(game_state.yellow().name()));
        }
        if (game_state.yellow().has_score()) {
            ui->yellowTeam->setScore(game_state.yellow().score());
        }
    }
    if (game_state.has_blue()) {
        if (game_state.blue().name().size() > 0) {
            ui->blueTeam->setTeamName(QString::fromStdString(game_state.blue().name()));
        }
        if (game_state.blue().has_score()) {
            ui->blueTeam->setScore(game_state.blue().score());
        }
    }
}


void InfoBoard::updateRefstate(const Status &status)
{
    bool change = false;

    if (status->has_debug()) {
        for (auto& debugMsg : status->debug().value()) {
            if (debugMsg.key() == "AUTOREF_EVENT" && debugMsg.has_string_value() &&
                    QString::fromStdString(debugMsg.string_value()) != m_foulEvent) {
                m_foulEvent = QString::fromStdString(debugMsg.string_value());
                m_eventMsgTime = status->time();
                m_autorefMsgInvalidated = false;
                change = true;
            } else if (debugMsg.key() == "AUTOREF_NEXT" && debugMsg.has_string_value() &&
                    QString::fromStdString(debugMsg.string_value()) != m_foulEvent) {
                m_nextAction = QString::fromStdString(debugMsg.string_value());
            }
        }
    }

    if (status->has_game_state()) {
        const amun::GameState &game_state = status->game_state();
        const amun::GameState::State state = game_state.state();
        QString stateName = QString::fromStdString(game_state.State_Name(state));
        if (state == amun::GameState::TimeoutBlue || state == amun::GameState::TimeoutYellow) {
            QString timeout = "";
            int timeoutLeft;
            if (state == amun::GameState::TimeoutBlue) {
                timeoutLeft = game_state.blue().timeout_time() / 1000000;
            } else {
                timeoutLeft = game_state.yellow().timeout_time() / 1000000;
            }
            timeout = QString(" (%1:%2)")
                    .arg(timeoutLeft / 60, 2, 10, QChar('0'))
                    .arg(timeoutLeft % 60, 2, 10, QChar('0'));
            stateName += timeout;
        }
        if (m_refState != stateName) {
            m_refState = stateName;
            change = true;
        }
    }

    if (change) {
        m_blinkTimer->start(700);

        if (status->time() - m_eventMsgTime > 10000 * 1E6 && !m_autorefIsActive) {
            // eventMsg older than 10s in passive mode
            m_autorefMsgInvalidated = true;
        } else if (status->time() - m_eventMsgTime > 150 * 1E6 && m_autorefIsActive &&
                m_refState != "Stop" && m_refState != "BallPlacementBlue" && m_refState != "BallPlacementYellow") {
            // we wait 150ms because the eventMsg may arrive before the ref message
            m_autorefMsgInvalidated = true;
        }

        // put space between first two words, newline before third word if any
        QString refStateNice = m_refState.replace(QRegExp("(.+)([A-Z])(.+)([A-Z])(.+)"), "\\1 \\2\\3<br>\\4\\5");
        refStateNice = refStateNice.replace(QRegExp("^(.+)([A-Z])(.+)"), "\\1 \\2\\3");

        QString displayText;
        if (m_autorefMsgInvalidated || m_foulEvent == "") {
            uint fontSize = ui->refState->height() / 4.1;
            displayText = QString(
                    "<p style=\"font-size: %1px; color: grey;\">Ref State</p>"
                    "<div style=\"font-size: %2px;\">%3</div>")
                    .arg((int)(fontSize*0.45))
                    .arg(fontSize)
                    .arg(refStateNice);
        } else if (!m_autorefIsActive) { // passive autoref, no next action
            uint fontSize = ui->refState->height() / 6.4;
            displayText = QString(
                    "<p style=\"font-size: %1px;\">%4</p><br>" // (foul) event message
                    "<p style=\"font-size: %1px; color: gray;\">Ref State</p>"
                    "<div style=\"font-size: %2px;\">%3</div>")
                .arg((int)(fontSize*0.65))
                .arg(fontSize)
                .arg(refStateNice)
                .arg(m_foulEvent);
        } else {
            uint fontSize = ui->refState->height() / 6.4;
            displayText = QString(
                    "<p style=\"font-size: %1px;\">%4</p>" // (foul) event message
                    "<br><table align=\"center\"><tr>"
                    "<td style=\"text-align: center;\">"
                    "<div style=\"margin-right: %1px; font-size: %1px; color: gray;\">Ref State</div>"
                    "<div style=\"margin-right: %1px;font-size: %2px;\">%3</div>"
                    "</td><td style=\"text-align: center;\">"
                    "<div style=\"margin-left: %1px;font-size: %1px; color: gray;\">Next Action</div>"
                    "<div style=\"margin-left: %1px;font-size: %2px;\">%5</div>"
                    "</td></tr></table>")
                .arg((int)(fontSize*0.65))
                .arg(fontSize)
                .arg(refStateNice)
                .arg(m_foulEvent)
                .arg(m_nextAction);
        }
        ui->refState->setText(displayText);
    }
}

void InfoBoard::handleStatus(const Status &status)
{
    if (status->has_game_state()) {
        const amun::GameState &game_state = status->game_state();
        updateGameStage(game_state);
        updateTime(game_state);
        updateTeamScores(game_state);
    }
    updateRefstate(status);
}

void InfoBoard::changeColor()
{
    //end blinking after eight colour changes
    if(m_blinkCounter == 9){
        m_blinkTimer->stop();
        m_blinkCounter = 1;
        return;
    }

    else if(m_blinkCounter%2){
        ui->refState->setStyleSheet("color:red");
    } else {
        ui->refState->setStyleSheet("");
    }
    m_blinkCounter++;
}

void InfoBoard::mouseDoubleClickEvent(QMouseEvent *event) {
    if(isFullScreen()) {
        setWindowState(Qt::WindowMaximized);
    } else {
        setWindowState(Qt::WindowFullScreen);
    }
}

void InfoBoard::setAutorefIsActive(bool active) {
    m_autorefIsActive = active;
}
