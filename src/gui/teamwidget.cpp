/***************************************************************************
 *   Copyright 2015 Michael Eischer, Philipp Nordhus                       *
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

#include "teamwidget.h"
#include "protobuf/command.pb.h"
#include "protobuf/status.pb.h"
#include <QAction>
#include <QBoxLayout>
#include <QContextMenuEvent>
#include <QFileDialog>
#include <QSettings>
#include <QToolButton>
#include <QMenu>

TeamWidget::TeamWidget(QWidget *parent) :
    QFrame(parent),
    m_userAutoReload(false),
    m_notification(false)
{
}

TeamWidget::~TeamWidget()
{
    QSettings s;
    s.beginGroup("RefereeTeam");
    s.setValue("Script", m_filename);
    s.setValue("EntryPoint", m_entryPoint);
    s.setValue("AutoReload", m_userAutoReload);
    s.endGroup();

    s.beginGroup("Strategy");
    s.setValue("RecentScripts", m_recentScripts);
    s.endGroup();
}

void TeamWidget::init()
{
    QBoxLayout *hLayout = new QHBoxLayout(this);
    hLayout->setMargin(4);
    hLayout->setSpacing(3);

    m_scriptMenu = new QMenu(this);
    m_actionDisable = m_scriptMenu->addAction("Disable");
    m_actionDisable->setVisible(false);
    connect(m_actionDisable, SIGNAL(triggered()), SLOT(closeScript()));
    QAction *action = m_scriptMenu->addAction("Browse");
    connect(action, SIGNAL(triggered()), SLOT(showOpenDialog()));
    connect(m_scriptMenu, SIGNAL(aboutToShow()), SLOT(prepareScriptMenu()));

    m_entryPoints = new QMenu(this);

    m_btnOpen = new QToolButton;
    m_btnOpen->setText("Autoref disabled");
    m_btnOpen->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
    m_btnOpen->setMenu(m_scriptMenu);
    m_btnOpen->setPopupMode(QToolButton::InstantPopup);
    connect(m_btnOpen, SIGNAL(clicked()), SLOT(showOpenDialog()));
    hLayout->addWidget(m_btnOpen);

    m_btnEntryPoint = new QToolButton;
    m_btnEntryPoint->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
    m_btnEntryPoint->setText("<no entrypoint>");
    m_btnEntryPoint->setVisible(false);
    m_btnEntryPoint->setPopupMode(QToolButton::InstantPopup);
    m_btnEntryPoint->setMenu(m_entryPoints);
    connect(m_btnEntryPoint, SIGNAL(triggered(QAction*)), SLOT(selectEntryPoint(QAction*)));
    hLayout->addWidget(m_btnEntryPoint);

    QMenu *reload_menu = new QMenu(this);
    m_reloadAction = reload_menu->addAction("Reload automatically");
    m_reloadAction->setCheckable(true);
    connect(m_reloadAction, SIGNAL(toggled(bool)), SLOT(sendAutoReload()));

    m_btnReload = new QToolButton;
    m_btnReload->setToolTip("Reload script");
    m_btnReload->setIcon(QIcon("icon:32/view-refresh.png"));
    m_btnReload->setPopupMode(QToolButton::MenuButtonPopup);
    m_btnReload->setMenu(reload_menu);
    connect(m_btnReload, SIGNAL(clicked()), SLOT(sendReload()));
    hLayout->addWidget(m_btnReload);

    updateStyleSheet();
}

void TeamWidget::load()
{
    QSettings s;
    s.beginGroup("Strategy");
    m_recentScripts = s.value("RecentScripts").toStringList();
    s.endGroup();

    s.beginGroup("RefereeTeam");
    m_filename = s.value("Script").toString();
    m_entryPoint = s.value("EntryPoint").toString();
    m_reloadAction->setChecked(s.value("AutoReload").toBool());
    s.endGroup();
    sendEnableDebug(true);

    if (QFileInfo(m_filename).exists()) {
        selectEntryPoint(m_entryPoint);
    } else {
        QString autoref_init_file = QString(AUTOREF_DIR)+"/autoref/init.lua";
        if (QFileInfo(autoref_init_file).exists()) {
            m_filename = autoref_init_file;
            selectEntryPoint(m_entryPoint);
        }
    }
}

void TeamWidget::forceAutoReload(bool force)
{
    // must be updated before call to setChecked!
    m_reloadAction->setDisabled(force); // disable when forced
    if (force) {
        m_reloadAction->setChecked(true);
    } else {
        m_reloadAction->setChecked(m_userAutoReload);
    }
}

void TeamWidget::handleStatus(const Status &status)
{
    // select corresponding strategy status
    const amun::StatusStrategy *strategy = NULL;
    if (status->has_strategy_autoref()) {
        strategy = &status->strategy_autoref();
    }

    if (strategy) {
        // only show entrypoint selection if > 0 entry points available
        m_btnEntryPoint->setVisible(strategy->entry_point_size() > 0);

        // rebuild entrypoint menu
        m_entryPoints->clear();
        for (int i = 0; i < strategy->entry_point_size(); i++) {
            const QString name = QString::fromStdString(strategy->entry_point(i));
            addEntryPoint(m_entryPoints, name, name);
        }

        // show entrypoint name
        if (strategy->has_current_entry_point()) {
            m_entryPoint = shortenEntrypointName(m_entryPoints, QString::fromStdString(strategy->current_entry_point()), 20);
            m_btnEntryPoint->setText(m_entryPoint);
        } else {
            m_entryPoint = QString();
            m_btnEntryPoint->setText("<no entrypoint>");
        }

        // strategy name
        m_btnOpen->setText(QString::fromStdString(strategy->name()));
        // status dependent display
        m_actionDisable->setVisible(strategy->state() != amun::StatusStrategy::CLOSED);

        switch (strategy->state()) {
        case amun::StatusStrategy::CLOSED:
            m_btnOpen->setText("Autoref disabled");
            m_notification = false;
            // clear strategy information
            m_filename = QString();
            m_entryPoint = QString();
            break;

        case amun::StatusStrategy::RUNNING:
            m_notification = false;
            break;

        case amun::StatusStrategy::FAILED:
            m_notification = true;
            break;
        }

        updateStyleSheet();
    }
}

void TeamWidget::addEntryPoint(QMenu *menu, const QString &name, const QString &entryPoint)
{
    int idx = name.indexOf("/");
    if (idx == -1) {
        QAction *action = menu->addAction(name);
        action->setData(entryPoint);
    } else {
        const QString nameLeft = name.left(idx);
        const QString nameRight = name.right(name.length() - idx - 1);
        QAction *action = NULL;
        if (!menu->actions().isEmpty()) {
            action = menu->actions().last();
        }

        QMenu *subMenu;
        if (action && action->text() == nameLeft) {
            subMenu = action->menu();
        } else {
            subMenu = menu->addMenu(nameLeft);
        }
        addEntryPoint(subMenu, nameRight, entryPoint);
    }
}

QString TeamWidget::shortenEntrypointName(const QMenu *menu, const QString &name, int targetLength)
{
    // shorten entry point name
    QString left = "";
    QString right = name;
    while (left.length() + 1 + right.length() > targetLength) {
        int idx = right.indexOf("/");
        if (idx == -1) {
            break;
        } else {
            const QString nameLeft = right.left(idx);
            const QString nameRight = right.right(right.length() - idx - 1);

            // strip as many characters as possible while staying nonambiguous
            int maxCommon = 0;
            const QMenu *nextMenu = nullptr;
            foreach(QAction *action, menu->actions()) {
                QString name = action->text();
                if (name == nameLeft) {
                    // must always be present once
                    nextMenu = action->menu();
                    continue;
                }
                for (int i = 0; i < name.length(); ++i) {
                    if (i >= nameLeft.length() || name.at(i) != nameLeft.at(i)) {
                        maxCommon = std::max(maxCommon, i);
                        break;
                    }
                }
            }
            Q_ASSERT(nextMenu != nullptr);
            // add one distinguishing characters
            left += ((left.isEmpty())?"" : "/") + nameLeft.left(maxCommon+1);
            right = nameRight;
            menu = nextMenu;
        }
    }
    return left + ((left.isEmpty())?"" : "/") + right;
}

void TeamWidget::showOpenDialog()
{
    QString filename = QFileDialog::getOpenFileName(this, "Open script", QString(), QString("Lua scripts (*.lua)"), 0, 0);
    if (filename.isNull()) {
        return;
    }

    open(filename);
}

void TeamWidget::open()
{
    QString filename = sender()->property("filename").toString();
    if (filename.isNull()) {
        return;
    }

    open(filename);
}

void TeamWidget::open(const QString &filename)
{
    m_filename = filename;

    // move script to front
    m_recentScripts.removeAll(filename);
    m_recentScripts.prepend(filename);
    // keep at most five most recent scripts
    while (m_recentScripts.size() > 5) {
        m_recentScripts.takeLast();
    }
    Command command(new amun::Command);
    amun::CommandStrategyLoad *strategy =
                command->mutable_strategy_autoref()->mutable_load();

    strategy->set_filename(filename.toStdString());
    emit sendCommand(command);
}

void TeamWidget::closeScript()
{
    Command command(new amun::Command);
    amun::CommandStrategy *strategy =
                command->mutable_strategy_autoref();

    strategy->mutable_close();
    emit sendCommand(command);
}

void TeamWidget::prepareScriptMenu()
{
    // only keep close and open... entries
    while (m_scriptMenu->actions().size() > 2) {
        m_scriptMenu->removeAction(m_scriptMenu->actions().last());
    }

    if (m_recentScripts.isEmpty()) {
        return;
    }

    // add seperator and filenames
    m_scriptMenu->addSeparator();
    foreach (const QString &script, m_recentScripts) {
        QAction *action = m_scriptMenu->addAction(script);
        action->setProperty("filename", script);
        connect(action, SIGNAL(triggered()), SLOT(open()));
    }
}

void TeamWidget::selectEntryPoint(const QString &entry_point)
{
    Command command(new amun::Command);
    amun::CommandStrategyLoad *strategy =
                command->mutable_strategy_autoref()->mutable_load();

    strategy->set_filename(m_filename.toStdString());
    strategy->set_entry_point(entry_point.toStdString());

    emit sendCommand(command);
}

void TeamWidget::selectEntryPoint(QAction* action)
{
    selectEntryPoint(action->data().toString());
}

void TeamWidget::sendReload()
{
    Command command(new amun::Command);
    amun::CommandStrategy *strategy = command->mutable_strategy_autoref();

    strategy->set_reload(true);
    emit sendCommand(command);
}

void TeamWidget::sendAutoReload()
{
    if (m_reloadAction->isEnabled()) {
        m_userAutoReload = m_reloadAction->isChecked();
    }
    Command command(new amun::Command);
    amun::CommandStrategy *strategy = command->mutable_strategy_autoref();

    strategy->set_auto_reload(m_reloadAction->isChecked());
    emit sendCommand(command);
}

void TeamWidget::sendEnableDebug(bool enable)
{
    Command command(new amun::Command);
    amun::CommandStrategy *strategy = command->mutable_strategy_autoref();

    strategy->set_enable_debug(enable);
    sendCommand(command);
}

void TeamWidget::updateStyleSheet()
{
    // update background and border color
    const QColor bgColor = m_notification ? "red" : QColor(Qt::darkGreen).lighter(170);

    QString ss("TeamWidget { background-color: %1; border-radius: 5px; }");
    setStyleSheet(ss.arg(bgColor.name()));
}
