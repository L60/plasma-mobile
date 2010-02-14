/*
 *   Copyright 2009 by Alan Alpert <alan.alpert@nokia.com>
 *   Copyright 2010 by Ménard Alexis <menard@kde.org>

 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef DATASOURCE_H
#define DATASOURCE_H
#include <QObject>
#include <Plasma/DataEngine>
#include <qml.h>

namespace Plasma
{
    class Applet;
    class DataEngine;
}

class DataSource : public QObject
{
    Q_OBJECT
public:
    DataSource(QObject* parent=0);

    Q_PROPERTY(bool valid READ valid);
    bool valid() const {return m_applet!=0;}

    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged);
    int interval() const {return m_interval;}
    void setInterval(int i) {if(i==m_interval) return; m_interval=i; emit intervalChanged();}

    Q_PROPERTY(QString engine READ engine WRITE setEngine NOTIFY engineChanged);
    QString engine() const {return m_engine;}
    void setEngine(const QString &e) {if(e==m_engine) return; m_engine=e; emit engineChanged();}

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged);
    QString source() const {return m_source;}
    void setSource(const QString &s);

    Q_PROPERTY(QStringList keys READ keys NOTIFY keysChanged);
    QStringList keys() const {return m_keys;}

public slots:
    void dataUpdated(const QString &sourceName, const Plasma::DataEngine::Data &data);
    void setupData();

signals:
    void intervalChanged();
    void engineChanged();
    void sourceChanged();
    void keysChanged();

private:

    QString m_id;
    int m_interval;
    QString m_source;
    QString m_engine;
    QStringList m_keys;
    Plasma::Applet* m_applet;
    Plasma::DataEngine* m_dataEngine;
    QString m_connectedSource;
    QmlContext* m_context;
};
QML_DECLARE_TYPE(DataSource);
#endif
