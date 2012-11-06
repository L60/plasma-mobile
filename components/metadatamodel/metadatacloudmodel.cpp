/*
    Copyright 2011 Marco Martin <notmart@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#include "metadatacloudmodel.h"

#include <QDBusConnection>
#include <QDBusServiceWatcher>

#include <KDebug>
#include <KMimeType>

#include <soprano/vocabulary.h>

#include <Nepomuk2/File>
#include <Nepomuk2/Query/AndTerm>
#include <Nepomuk2/Query/ResourceTerm>
#include <Nepomuk2/Tag>
#include <Nepomuk2/Variant>
#include <nepomuk2/comparisonterm.h>
#include <nepomuk2/literalterm.h>
#include <nepomuk2/queryparser.h>
#include <nepomuk2/resourcetypeterm.h>
#include <nepomuk2/standardqueries.h>

#include <nepomuk2/nfo.h>
#include <nepomuk2/nie.h>

#include <kao.h>


MetadataCloudModel::MetadataCloudModel(QObject *parent)
    : AbstractMetadataModel(parent),
      m_queryClient(0),
      m_showEmptyCategories(false)
{
    QHash<int, QByteArray> roleNames;
    roleNames[Label] = "label";
    roleNames[Count] = "count";
    roleNames[TotalCount] = "totalCount";
    setRoleNames(roleNames);
}

MetadataCloudModel::~MetadataCloudModel()
{
}


void MetadataCloudModel::setCloudCategory(QString category)
{
    if (m_cloudCategory == category) {
        return;
    }

    m_cloudCategory = category;
    requestRefresh();
    emit cloudCategoryChanged();
}

QString MetadataCloudModel::cloudCategory() const
{
    return m_cloudCategory;
}

QVariantList MetadataCloudModel::categories() const
{
    return m_categories;
}

void MetadataCloudModel::setAllowedCategories(const QVariantList &whitelist)
{
    QSet<QString> set = variantToStringList(whitelist).toSet();

    if (set == m_allowedCategories) {
        return;
    }

    m_allowedCategories = set;
    requestRefresh();
    emit allowedCategoriesChanged();
}

QVariantList MetadataCloudModel::allowedCategories() const
{
    return stringToVariantList(m_allowedCategories.values());
}

void MetadataCloudModel::setShowEmptyCategories(bool show)
{
    if (show == m_showEmptyCategories) {
        return;
    }

    m_showEmptyCategories = show;
    requestRefresh();
    emit showEmptyCategoriesChanged();
}

bool MetadataCloudModel::showEmptyCategories() const
{
    return m_showEmptyCategories;
}


void MetadataCloudModel::doQuery()
{
    QDeclarativePropertyMap *parameters = qobject_cast<QDeclarativePropertyMap *>(extraParameters());

    //check if really all properties to build the query are null
    if (m_cloudCategory.isEmpty()) {
        return;
    }

    setRunning(true);
    QString query;

    if (!m_showEmptyCategories) {
        query += "select * where { filter(?count != 0) { ";
    }
    query += "select distinct ?label "
          "sum(?localWeight) as ?count "
          "sum(?globalWeight) as ?totalCount "
        "where {  ?r nie:url ?h . "
        "{ select distinct ?r ?label "
           "1 as ?localWeight "
           "0 as ?globalWeight "
          "where {";

    if (m_cloudCategory == "kao:Activity") {
        query += " ?activity nao:isRelated ?r . ?activity rdf:type kao:Activity . ?activity kao:activityIdentifier ?label ";
    } else {
        query += " ?r " + m_cloudCategory + " ?label";
    }


    if (!resourceType().isEmpty()) {
        QString type = resourceType();
        bool negation = false;
        if (type.startsWith('!')) {
            type = type.remove(0, 1);
            negation = true;
        }
        if (negation) {
            query += " . FILTER(!bif:exists((select (1) where { ?r rdf:type " + type + " . }))) ";
        } else {
            query += " . ?r rdf:type " + type;
        }

        if (type != "nfo:Bookmark") {
            //FIXME: remove bookmarks if not explicitly asked for
            query += " . FILTER(!bif:exists((select (1) where { ?r a <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#Bookmark> . }))) ";
        }
    }

    if (!mimeTypeStrings().isEmpty()) {
        query += " { ";
        bool first = true;
        foreach (QString type, mimeTypeStrings()) {
            bool negation = false;
            if (!first) {
                query += " UNION ";
            }
            first = false;
            if (type.startsWith('!')) {
                type = type.remove(0, 1);
                negation = true;
            }
            if (negation) {
                query += " { . FILTER(!bif:exists((select (1) where { ?r nie:mimeType \"" + type + "\"^^<http://www.w3.org/2001/XMLSchema#string> . }))) } ";
            } else {
                query += " { ?r nie:mimeType \"" + type + "\"^^<http://www.w3.org/2001/XMLSchema#string> . } ";
            }
        }
        query += " } ";
    }

    if (parameters && parameters->size() > 0) {
        foreach (const QString &key, parameters->keys()) {
            QString parameter = parameters->value(key).toString();
            bool negation = false;
            if (parameter.startsWith('!')) {
                parameter = parameter.remove(0, 1);
                negation = true;
            }

            if (negation) {
                query += " . FILTER(!bif:exists((select (1) where { ?r " + key + " ?mimeType . FILTER(bif:contains(?mimeType, \"'" + parameter + "'\")) . }))) ";
            } else {
                query += " . ?r " + key + " ?mimeType . FILTER(bif:contains(?mimeType, \"'" + parameter + "'\")) ";
            }
        }
    }

    if (!activityId().isEmpty()) {
        QString activity = activityId();
        bool negation = false;
        if (activity.startsWith('!')) {
            activity = activity.remove(0, 1);
            negation = true;
        }
        Nepomuk2::Resource acRes(activity, Nepomuk2::Vocabulary::KAO::Activity());

        if (negation) {
            query +=  ". FILTER(!bif:exists((select (1) where { <" + acRes.uri().toString() + "> <http://www.semanticdesktop.org/ontologies/2007/08/15/nao#isRelated> ?r . }))) ";
        } else {
            query +=  " . <" + acRes.uri().toString() + "> nao:isRelated ?r ";
        }
    }

    //this is an AND set of tags.. should be allowed OR as well?
    foreach (const QString &tag, tagStrings()) {
        QString individualTag = tag;
        bool negation = false;

        if (individualTag.startsWith('!')) {
            individualTag = individualTag.remove(0, 1);
            negation = true;
        }

        if (negation) {
            query += ". FILTER(!bif:exists((select (1) where { ?r nao:hasTag ?tagSet \
                    . ?tagSet ?tagLabel ?tag \
                    . ?tagLabel <http://www.w3.org/2000/01/rdf-schema#subPropertyOf> <http://www.w3.org/2000/01/rdf-schema#label> \
                    . FILTER(bif:contains(?tag, \"'"+individualTag+"'\"))}))) ";
        } else {
            query += ". ?r nao:hasTag ?tagSet \
                    . ?tagSet ?tagLabel ?tag \
                    . ?tagLabel <http://www.w3.org/2000/01/rdf-schema#subPropertyOf> <http://www.w3.org/2000/01/rdf-schema#label> \
                    . FILTER(bif:contains(?tag, \"'"+individualTag+"'\")) ";
        }
    }

    if (startDate().isValid() || endDate().isValid()) {
        if (startDate().isValid()) {
            query += " . { \
            ?r <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#lastModified> ?v2 . FILTER(?v2>\"" + startDate().toString(Qt::ISODate) + "\"^^<http://www.w3.org/2001/XMLSchema#dateTime>) . \
            } UNION {\
            ?r <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#contentCreated> ?v3 . FILTER(?v3>\"" + startDate().toString(Qt::ISODate) + "\"^^<http://www.w3.org/2001/XMLSchema#dateTime>) . \
            } UNION {\
            ?v4 <http://www.semanticdesktop.org/ontologies/2010/01/25/nuao#involves> ?r .\
            ?v4 <http://www.semanticdesktop.org/ontologies/2010/01/25/nuao#start> ?v5 .\ FILTER(?v5>\"" + startDate().toString(Qt::ISODate) + "\"^^<http://www.w3.org/2001/XMLSchema#dateTime>) . \
            }";
        }
        if (endDate().isValid()) {
            query += " . { \
            ?r <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#lastModified> ?v2 . FILTER(?v2<\"" + endDate().toString(Qt::ISODate) + "\"^^<http://www.w3.org/2001/XMLSchema#dateTime>) . \
            } UNION {\
            ?r <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#contentCreated> ?v3 . FILTER(?v3<\"" + endDate().toString(Qt::ISODate) + "\"^^<http://www.w3.org/2001/XMLSchema#dateTime>) . \
            } UNION {\
            ?v4 <http://www.semanticdesktop.org/ontologies/2010/01/25/nuao#involves> ?r .\
            ?v4 <http://www.semanticdesktop.org/ontologies/2010/01/25/nuao#start> ?v5 .\ FILTER(?v5<\"" + endDate().toString(Qt::ISODate) + "\"^^<http://www.w3.org/2001/XMLSchema#dateTime>) . \
            }";
        }
    }

    if (minimumRating() > 0) {
        query += " . ?r nao:numericRating ?rating filter (?rating >=" + QString::number(minimumRating()) + ") ";
    }

    if (maximumRating() > 0) {
        query += " . ?r nao:numericRating ?rating filter (?rating <=" + QString::number(maximumRating()) + ") ";
    }

    //Exclude who doesn't have url
    query += " . ?r nie:url ?h . ";

    //User visibility filter doesn't seem to have an acceptable speed
    //query +=  " . FILTER(bif:exists((select (1) where { ?r a [ <http://www.semanticdesktop.org/ontologies/2007/08/15/nao#userVisible> \"true\"^^<http://www.w3.org/2001/XMLSchema#boolean> ] . }))) } group by ?label order by ?label";

    query += "}} UNION { "
              "select distinct ?r ?label "
                "0 as ?localWeight "
                "1 as ?globalWeight "
              "where { "
                "?r " + m_cloudCategory + " ?label . "
                "?r nie:url ?h . }}";

    query +=  " } group by ?label order by ?label";

    if (!m_showEmptyCategories) {
        query +=  " }} ";
    }

    kDebug() << "Performing the Sparql query" << query;

    beginResetModel();
    m_results.clear();
    endResetModel();
    emit countChanged();

    delete m_queryClient;
    m_queryClient = new Nepomuk2::Query::QueryServiceClient(this);

    connect(m_queryClient, SIGNAL(newEntries(QList<Nepomuk2::Query::Result>)),
            this, SLOT(newEntries(QList<Nepomuk2::Query::Result>)));
    connect(m_queryClient, SIGNAL(entriesRemoved(QList<QUrl>)),
            this, SLOT(entriesRemoved(QList<QUrl>)));
    connect(m_queryClient, SIGNAL(finishedListing()), this, SLOT(finishedListing()));

    m_queryClient->sparqlQuery(query);
}

void MetadataCloudModel::newEntries(const QList< Nepomuk2::Query::Result > &entries)
{
    QVector<QHash<int, QVariant> > results;
    QVariantList categories;

    foreach (const Nepomuk2::Query::Result &res, entries) {
        QString label;
        int count = res.additionalBinding(QLatin1String("count")).variant().toInt();
        int totalCount = res.additionalBinding(QLatin1String("totalCount")).variant().toInt();
        QVariant rawLabel = res.additionalBinding(QLatin1String("label")).variant();

        if (rawLabel.canConvert<Nepomuk2::Resource>()) {
            label = rawLabel.value<Nepomuk2::Resource>().type().toString().section( QRegExp( "[#:]" ), -1 );
        } else if (!rawLabel.value<QUrl>().scheme().isEmpty()) {
            const QUrl url = rawLabel.value<QUrl>();
            if (url.scheme() == "nepomuk") {
                label = Nepomuk2::Resource(url).genericLabel();
            //TODO: it should convert from ontology url to short form nfo:Document
            } else {
                label = propertyShortName(url);
            }
        } else if (rawLabel.canConvert<QString>()) {
            label = rawLabel.toString();
        } else if (rawLabel.canConvert<int>()) {
            label = QString::number(rawLabel.toInt());
        } else {
            continue;
        }

        if (label.isEmpty() ||
            !(m_allowedCategories.isEmpty() || m_allowedCategories.contains(label))) {
            continue;
        }
        QHash<int, QVariant> result;
        result[Label] = label;
        result[Count] = count;
        result[TotalCount] = totalCount;
        results << result;
        categories << label;
    }
    if (results.count() > 0) {
        beginInsertRows(QModelIndex(), m_results.count(), m_results.count()+results.count()-1);
        m_results << results;
        m_categories << categories;
        endInsertRows();
        emit countChanged();
        emit categoriesChanged();
    }
}

void MetadataCloudModel::entriesRemoved(const QList<QUrl> &urls)
{
    //FIXME: optimize
    kDebug()<<urls;
    foreach (const QUrl &url, urls) {
        const QString propName = propertyShortName(url);
        int i = 0;
        int index = -1;
        foreach (const QVariant &v, m_categories) {
            QString cat = v.toString();
            if (cat == propName) {
                index = i;
                break;
            }
            ++i;
        }
        if (index >= 0 && index < m_results.size()) {
            beginRemoveRows(QModelIndex(), index, index);
            m_results.remove(index);
            endRemoveRows();
        }
    }
    emit countChanged();
}

void MetadataCloudModel::finishedListing()
{
    setRunning(false);
}



QVariant MetadataCloudModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.column() != 0 ||
        index.row() < 0 || index.row() >= m_results.count()){
        return QVariant();
    }

    return m_results[index.row()].value(role);

}

#include "metadatacloudmodel.moc"
