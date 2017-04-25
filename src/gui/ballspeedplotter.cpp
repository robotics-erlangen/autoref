/***************************************************************************
 *   Copyright 2015 Michael Eischer, Jan Kallwies, Philipp Nordhus         *
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

#include "leaffilterproxymodel.h"
#include "ballspeedplotter.h"
#include "plot.h"
#include "guitimer.h"
#include "ui_ballspeedplotter.h"
#include "google/protobuf/descriptor.h"
#include "protobuf/status.pb.h"
#include <cmath>
#include <QStringBuilder>
#include <unordered_map>

BallSpeedPlotter::BallSpeedPlotter(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::BallSpeedPlotter),
    m_startTime(0),
    m_freeze(false)
{
    ui->setupUi(this);

    // proxy model for tree filtering
    m_proxy = new LeafFilterProxyModel(this);
    m_proxy->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_proxy->setSourceModel(&m_model);

    // root items in the plotter
    addRootItem(QStringLiteral("Ball"), QStringLiteral("Ball"));

    // connect freeze
    connect(ui->btnFreeze, SIGNAL(toggled(bool)), this, SLOT(setFreeze(bool)));

    // connect the plot widget
    connect(this, SIGNAL(addPlot(const Plot*)), ui->widget, SLOT(addPlot(const Plot*)));

    // setup invalidate timer
    m_guiTimer = new GuiTimer(1000, this);
    connect(m_guiTimer, &GuiTimer::timeout, this, &BallSpeedPlotter::invalidatePlots);

    m_timeLimit = 120;
    ui->widget->setYMin(0);
    ui->widget->setYMax(11);
    m_selection.insert("Ball.v_global");
}

BallSpeedPlotter::~BallSpeedPlotter()
{
    delete ui;
    qDeleteAll(m_plots);
    qDeleteAll(m_frozenPlots);
}

void BallSpeedPlotter::addRootItem(const QString &name, const QString &displayName)
{
    QStandardItem *item = new QStandardItem(displayName);
    m_model.appendRow(item);
    m_items[name] = item;
}

void BallSpeedPlotter::setFreeze(bool freeze)
{
    if (!freeze && m_freeze) {
        // merge plots on unfreezing
        foreach (QStandardItem *item, m_items) {
            Plot *freezePlot = m_frozenPlots.value(item, nullptr);
            if (freezePlot == nullptr) {
                continue;
            }
            // remove freeze plot entry
            m_frozenPlots.remove(item);

            Plot *plot = m_plots.value(item, nullptr);
            if (plot != nullptr) { // merge freeze plot if there's already a plot
                plot->mergeFrom(freezePlot);
                delete freezePlot;
            } else { // otherwise reuse it as plot
                m_plots[item] = freezePlot;
            }
        }
    }
    m_freeze = freeze;
    ui->btnFreeze->setChecked(freeze); // update button
}

void BallSpeedPlotter::handleStatus(const Status &status)
{
    // don't consume cpu while closed
    if (!isVisible()) {
        return;
    }

    m_guiTimer->requestTriggering();

    m_time = status->time();
    // normalize time to be able to store it in floats
    if (m_startTime == 0) {
        m_startTime = status->time();
    }

    const float time = (status->time() - m_startTime) / 1E9;

    // handle each message
    if (status->has_world_state()) {
        const world::State &worldState = status->world_state();
        float time = (worldState.time() - m_startTime) / 1E9;

        if (worldState.has_ball()) {
            parseMessage(worldState.ball(), QStringLiteral("Ball"), time);
        }
    }

    // don't move plots during freeze
    if (!m_freeze) {
        ui->widget->update(time);
    }
}

QStandardItem* BallSpeedPlotter::getItem(const QString &name)
{
    // item already exists
    if (m_items.contains(name)) {
        return m_items[name];
    }

    int split = name.lastIndexOf(QChar('.'));
    if (split == -1) { // silently handle the case that the root item is missing
        addRootItem(name, name);
        return m_items[name];
    }

    // create new item and add it to the model
    const QString parentName = name.mid(0, split);
    const QString childName = name.mid(split + 1);
    QStandardItem *parent = getItem(parentName);
    QStandardItem *child = new QStandardItem(childName);
    child->setData(name, BallSpeedPlotter::FullNameRole);
    m_items[name] = child;
    parent->appendRow(child);
    return child;
}

void BallSpeedPlotter::invalidatePlots()
{
    if (!isVisible()) { // values aren't update while hidden
        return;
    }

    const float time = (m_time - m_startTime) / 1E9;

    foreach (QStandardItem *item, m_items) {
        // check the role that is currently updated
        QHash<QStandardItem*, Plot*> &plots = (m_freeze) ? m_frozenPlots : m_plots;
        Plot *plot = plots.value(item, nullptr);
        if (plot == nullptr) {
            continue;
        }
        if (plot->time() + 5 < time) {
            // mark old plots
            item->setForeground(Qt::gray);
        }
    }
}

enum class SpecialFieldNames: int {
    none = 0,
    v_f = 1,
    v_s = 2,
    v_x = 3,
    v_y = 4,
    v_d_x = 5,
    v_d_y = 6,
    v_ctrl_out_f = 7,
    v_ctrl_out_s = 8,
    max = 9
};

static const std::unordered_map<std::string, SpecialFieldNames> fieldNameMap = {
    std::make_pair("v_f", SpecialFieldNames::v_f),
    std::make_pair("v_s", SpecialFieldNames::v_s),
    std::make_pair("v_x", SpecialFieldNames::v_x),
    std::make_pair("v_y", SpecialFieldNames::v_y),
    std::make_pair("v_desired_x", SpecialFieldNames::v_d_x),
    std::make_pair("v_desired_y", SpecialFieldNames::v_d_y),
    std::make_pair("v_ctrl_out_f", SpecialFieldNames::v_ctrl_out_f),
    std::make_pair("v_ctrl_out_s", SpecialFieldNames::v_ctrl_out_s),
};

void BallSpeedPlotter::parseMessage(const google::protobuf::Message &message, const QString &parent, float time)
{
    const google::protobuf::Descriptor *desc = message.GetDescriptor();
    const google::protobuf::Reflection *refl = message.GetReflection();

    float specialFields[static_cast<int>(SpecialFieldNames::max)];
    for (int i = 0; i < static_cast<int>(SpecialFieldNames::max); ++i) {
        specialFields[i] = NAN;
    }

    const int extraFields = 4;
    if (!m_itemLookup.contains(parent)) {
        m_itemLookup[parent] = QVector<QStandardItem *>(desc->field_count() + extraFields, nullptr);
    }
    // just a performance optimization
    QVector<QStandardItem *> &childLookup = m_itemLookup[parent];

    for (int i = 0; i < desc->field_count(); i++) {
        const google::protobuf::FieldDescriptor *field = desc->field(i);

        // check type and that the field exists
        if (field->cpp_type() == google::protobuf::FieldDescriptor::CPPTYPE_FLOAT
                && refl->HasField(message, field)) {
            const std::string &name = field->name();
            const float value = refl->GetFloat(message, field);
            if (fieldNameMap.count(name) > 0) {
                SpecialFieldNames fn = fieldNameMap.at(name);
                specialFields[static_cast<int>(fn)] = value;
            }
            addPoint(name, parent, time, value, childLookup, i);
        } else if (field->cpp_type() == google::protobuf::FieldDescriptor::CPPTYPE_BOOL
                   && refl->HasField(message, field)) {
            const std::string &name = field->name();
            const float value = refl->GetBool(message,field) ? 1 : 0;
            addPoint(name, parent, time, value, childLookup, i);
        }
    }

    // precompute strings
    static const std::string staticVLocal("v_local");
    static const std::string staticVDesired("v_desired");
    static const std::string staticVCtrlOut("v_ctrl_out");
    static const std::string staticVGlobal("v_global");

    // add length of speed vectors
    tryAddLength(staticVLocal, parent, time,
                 specialFields[static_cast<int>(SpecialFieldNames::v_f)],
                 specialFields[static_cast<int>(SpecialFieldNames::v_s)],
                 childLookup, desc->field_count()+0);
    tryAddLength(staticVDesired, parent, time,
                 specialFields[static_cast<int>(SpecialFieldNames::v_d_x)],
                 specialFields[static_cast<int>(SpecialFieldNames::v_d_y)],
                 childLookup, desc->field_count()+1);
    tryAddLength(staticVCtrlOut, parent, time,
                 specialFields[static_cast<int>(SpecialFieldNames::v_ctrl_out_f)],
                 specialFields[static_cast<int>(SpecialFieldNames::v_ctrl_out_f)],
                 childLookup, desc->field_count()+2);
    tryAddLength(staticVGlobal, parent, time,
                 specialFields[static_cast<int>(SpecialFieldNames::v_x)],
                 specialFields[static_cast<int>(SpecialFieldNames::v_y)],
                 childLookup, desc->field_count()+3);
}

void BallSpeedPlotter::tryAddLength(const std::string &name, const QString &parent, float time, float value1, float value2,
                           QVector<QStandardItem *> &childLookup, int descriptorIndex)
{
    // if both values are set
    if (!std::isnan(value1) && !std::isnan(value2)) {
        const float value = std::sqrt(value1 * value1 + value2 * value2);
        addPoint(name, parent, time, value, childLookup, descriptorIndex);
    }
}

void BallSpeedPlotter::addPoint(const std::string &name, const QString &parent, float time, float value,
                       QVector<QStandardItem *> &childLookup, int descriptorIndex)
{
    QStandardItem *item;
    if (childLookup.isEmpty() || childLookup[descriptorIndex] == nullptr) {
        // full name for item retrieval
        const QString fullName = parent % QStringLiteral(".") % QString::fromStdString(name);
        item = getItem(fullName);
        if (!childLookup.isEmpty()) {
            childLookup[descriptorIndex] = item;
        }
    } else {
        item = childLookup[descriptorIndex];
    }

    // save data into a hidden plot while freezed
    QHash<QStandardItem*, Plot*> &plots = (m_freeze) ? m_frozenPlots : m_plots;
    Plot *plot = plots.value(item, nullptr);

    if (plot == nullptr) { // create new plot
        const QString fullName = parent % QStringLiteral(".") % QString::fromStdString(name);
        plot = new Plot(fullName, this);
        item->setCheckable(true);
        if (m_selection.contains(fullName)) {
            addPlot(plot); // manually add plot as itemChanged won't add it
            item->setCheckState(Qt::Checked);
        } else {
            item->setCheckState(Qt::Unchecked);
        }
        // set plot information after the check state
        // itemChanged only checks items in m_plots
        // thus no enable / disable flickering will occur
        plots[item] = plot;
    }
    // only clear foreground if it's set, causes a serious performance regression
    // if it's always done
    if (item->data(Qt::ForegroundRole).isValid()) {
        item->setData(QVariant(), Qt::ForegroundRole); // clear foreground color
    }
    plot->addPoint(time, value);
}
