/*
 *   Copyright (C) 2010 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License version 2 as
 *   published by the Free Software Foundation
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

#include "recommendationsengine.h"
#include "testsource.h"

#include <QDBusPendingCallWatcher>

#include <KDebug>

#include <recommendationsclient.h>
#include <recommendation.h>
#include <recommendationaction.h>

RecommendationsEngine::RecommendationsEngine(QObject* parent, const QVariantList& args)
    : Plasma::DataEngine(parent, args)
{
    setMinimumPollingInterval(2 * 1000); // 2 seconds minimum

    m_recommendationsClient = new Contour::RecommendationsClient(this);
    connect(m_recommendationsClient, SIGNAL(recommendationsChanged(const QList<Contour::Recommendation> &)), this, SLOT(updateRecommendations(const QList<Contour::Recommendation> &)));
}

RecommendationsEngine::~RecommendationsEngine()
{
}

void RecommendationsEngine::updateRecommendations(const QList<Contour::Recommendation> &recommendations)
{
    m_recommendations = recommendations;
    m_recommendationsResources.clear();

    foreach (Contour::Recommendation rec, recommendations) {
        Nepomuk::Resource res(rec.resourceUri);
        m_recommendationsResources[rec.resourceUri] = res;

        setData(rec.resourceUri, "name", res.genericLabel());
        setData(rec.resourceUri, "description", res.genericDescription());
        setData(rec.resourceUri, "icon", res.genericIcon());
        setData(rec.resourceUri, "relevance", rec.relevance);

        QVariantList actionsList;
        foreach (Contour::RecommendationAction action, rec.actions) {
            DataEngine::Data actionData;
            actionData["id"] = action.id;
            actionData["text"] = action.text;
            actionData["iconName"] = action.iconName;
            actionData["relevance"] = action.relevance;
        }
        setData(rec.resourceUri, "actions", actionsList);
    }
}

#include "recommendationsengine.moc"
