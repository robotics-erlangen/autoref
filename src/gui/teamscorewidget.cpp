/***************************************************************************
 *   Copyright 2016 Alexander Danzer                                       *
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

#include <QLabel>
#include "teamscorewidget.h"
#include "ui_teamscorewidget.h"
#include "config.h"

TeamScoreWidget::TeamScoreWidget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::TeamScoreWidget),
    m_isBlue(false),
    m_teamName(),
    m_score(0)
{
    ui->setupUi(this);
    ui->team->setText("Yellow Team");
}

TeamScoreWidget::~TeamScoreWidget()
{
    delete ui;
}

void TeamScoreWidget::resizeEvent(QResizeEvent *event)
{
    // unsetting values triggers font-size recalculation
    m_teamName = "";
    m_score = -1;
}

void TeamScoreWidget::setTeamBlue()
{
    m_isBlue = true;
    ui->team->setText("Blue Team");
}

void TeamScoreWidget::setTeamName(const QString& teamName)
{
    if (teamName != m_teamName) {
        m_teamName = teamName;
        if (!setLogo()) {
            ui->team->setText(m_teamName);
            ui->team->setStyleSheet(QString("font-size:") +
                QString::number((int)(this->height()/m_teamName.size()*1.2)) + "px;");
        }
    }
}

void TeamScoreWidget::setScore(int score)
{
    if (score != m_score) {
        m_score = score;
        ui->score->setStyleSheet(QString("font-size:") +
            QString::number((int)(this->height()*0.4)) + "px;");
        ui->score->setText(QString::number(m_score));
    }
}

bool TeamScoreWidget::setLogo()
{
    QPixmap pix(QString("logo:%1.png").arg(m_teamName));
    if (!pix.isNull()) {
        ui->team->setPixmap((pix.scaledToWidth((int)ui->team->width()*0.7)));
        return true;
    }
    return false;
}
