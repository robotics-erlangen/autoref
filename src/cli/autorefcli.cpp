/***************************************************************************
 *   Copyright 2021 Paul Bergmann                                          *
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

#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QMetaObject>
#include <QObject>
#include <QString>
#include <QTime>
#include <QtGlobal>

#include "amun/amunclient.h"
#include "core/sslprotocols.h"
#include "protobuf/command.h"
#include "protobuf/status.h"
#include "seshat/logfilewriter.h"
#include "testtools.h"

#define TIMESTAMP (qPrintable(QTime::currentTime().toString()))

namespace {

const QString DEFAULT_INIT_SCRIPT = AUTOREF_DIR "/autoref/init.lua";

struct Settings {
    LogFileWriter m_logfile;
    QString m_initScript = DEFAULT_INIT_SCRIPT;
    QString m_entryPoint;
    std::uint32_t m_visionPort = SSL_VISION_PORT;
    std::uint32_t m_gameControllerPort = SSL_GAME_CONTROLLER_PORT;
};

void getSettings(Settings& settings) {
    QCommandLineParser parser;
    parser.setApplicationDescription("Command line interface for the ER-Force autoref");
    parser.addHelpOption();

    QCommandLineOption recordLogOption { "record", "Record the game to the specified log file", "logfile" };
    QCommandLineOption visionPortOption { "vision-port", "Port to receive vision detections on", "vision-port" };
    QCommandLineOption gameControllerPortOption { "gc-port", "Port to receive game controller/referee messages on", "gc-port" };

    parser.addOption(recordLogOption);
    parser.addOption(visionPortOption);
    parser.addOption(gameControllerPortOption);

    parser.process(*QCoreApplication::instance());

    if (parser.isSet(recordLogOption)) {
        settings.m_logfile.open(parser.value(recordLogOption));
    }

    if (parser.isSet(visionPortOption)) {
        const int port = parser.value(visionPortOption).toInt();
        if (port <= 0) {
            qFatal("Invalid vision port, must be positive");
            std::exit(1);
        }
        settings.m_visionPort = port;
    }

    if (parser.isSet(gameControllerPortOption)) {
        const int port = parser.value(gameControllerPortOption).toInt();
        if (port <= 0) {
            qFatal("Invalid game controller port, must be positive");
            std::exit(1);
        }
        settings.m_gameControllerPort = port;
    }
}

Command buildCommand(const Settings& settings) {
    Command command { new amun::Command };

    amun::CommandStrategy *strategy = command->mutable_strategy_autoref();
    strategy->set_enable_debug(true);
    auto *load = strategy->mutable_load();
    load->set_filename(settings.m_initScript.toStdString());
    load->set_entry_point(settings.m_entryPoint.toStdString());

    amun::CommandAmun *amun = command->mutable_amun();
    amun->set_vision_port(settings.m_visionPort);
    amun->set_referee_port(settings.m_gameControllerPort);

    return command;
}

}

int main(int argc, char* argv[]) {
    QCoreApplication app { argc, argv };
    app.setApplicationName("Autoref-CLI");
    app.setOrganizationName("ER-Force");

    Settings settings;
    getSettings(settings);
    Command command = buildCommand(settings);

    AmunClient amun;
    amun.start();

    amun::GameState_State currentGameState = amun::GameState_State_Halt;

    QObject::connect(&amun, &AmunClient::gotStatus, [&settings, &currentGameState](const Status &status) {
        settings.m_logfile.writeStatus(status);

        for (const auto &debug : status->debug()) {
            for (const auto &entry : debug.log()) {
                QString text = TestTools::stripHTML(QString::fromStdString(entry.text()));
                qInfo("%s %s", TIMESTAMP, qPrintable(text));
            }
        }

        if (status->has_game_state() && currentGameState != status->game_state().state()) {
            currentGameState = status->game_state().state();
            qInfo("%s Switched state to %s\n", TIMESTAMP, amun::GameState_State_Name(currentGameState).c_str());
        }
    });

    QMetaObject::invokeMethod(&amun, "sendCommand", Q_ARG(Command, command));

    return app.exec();
}

