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

#ifndef TEAMSCOREWIDGET_H
#define TEAMSCOREWIDGET_H

#include <QLabel>

namespace Ui {
class TeamScoreWidget;
}

class TeamScoreWidget : public QWidget
{
    Q_OBJECT

public:
    explicit TeamScoreWidget(QWidget *parent);
    ~TeamScoreWidget() override;

    void setScore(int score);
    void setTeamName(const QString& teamName);
    void setTeamBlue(); // default is yellow

protected:
    void resizeEvent(QResizeEvent *event) override;

private:
    Ui::TeamScoreWidget *ui;
    bool m_isBlue;
    QString m_teamName;
    int m_score;
    bool setLogo();
};

#endif // TEAMSCOREWIDGET_H
