/****************************************************************************
** Meta object code from reading C++ file 'textcreator.cpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.12.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <QtCore/qmetatype.h>
#include <QtCore/qplugin.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'textcreator.cpp' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.12.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN18TextCreatorFactoryE_t {};
} // unnamed namespace

template <> constexpr inline auto TextCreatorFactory::qt_create_metaobjectdata<qt_meta_tag_ZN18TextCreatorFactoryE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "TextCreatorFactory"
    };

    QtMocHelpers::UintData qt_methods {
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<TextCreatorFactory, qt_meta_tag_ZN18TextCreatorFactoryE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject TextCreatorFactory::staticMetaObject = { {
    QMetaObject::SuperData::link<KPluginFactory::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18TextCreatorFactoryE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18TextCreatorFactoryE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN18TextCreatorFactoryE_t>.metaTypes,
    nullptr
} };

void TextCreatorFactory::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<TextCreatorFactory *>(_o);
    (void)_t;
    (void)_c;
    (void)_id;
    (void)_a;
}

const QMetaObject *TextCreatorFactory::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *TextCreatorFactory::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18TextCreatorFactoryE_t>.strings))
        return static_cast<void*>(this);
    if (!strcmp(_clname, "org.kde.KPluginFactory"))
        return static_cast< KPluginFactory*>(this);
    return KPluginFactory::qt_metacast(_clname);
}

int TextCreatorFactory::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = KPluginFactory::qt_metacall(_c, _id, _a);
    return _id;
}

#ifdef QT_MOC_EXPORT_PLUGIN_V2
static constexpr unsigned char qt_pluginMetaDataV2_TextCreatorFactory[] = {
    0xbf, 
    // "IID"
    0x02,  0x76,  'o',  'r',  'g',  '.',  'k',  'd', 
    'e',  '.',  'K',  'P',  'l',  'u',  'g',  'i', 
    'n',  'F',  'a',  'c',  't',  'o',  'r',  'y', 
    // "className"
    0x03,  0x72,  'T',  'e',  'x',  't',  'C',  'r', 
    'e',  'a',  't',  'o',  'r',  'F',  'a',  'c', 
    't',  'o',  'r',  'y', 
    // "MetaData"
    0x04,  0xa2,  0x6e,  'C',  'a',  'c',  'h',  'e', 
    'T',  'h',  'u',  'm',  'b',  'n',  'a',  'i', 
    'l',  0xf4,  0x67,  'K',  'P',  'l',  'u',  'g', 
    'i',  'n',  0xa2,  0x69,  'M',  'i',  'm',  'e', 
    'T',  'y',  'p',  'e',  's',  0x81,  0x6a,  't', 
    'e',  'x',  't',  '/',  'p',  'l',  'a',  'i', 
    'n',  0x64,  'N',  'a',  'm',  'e',  0x6f,  'F', 
    'o',  'l',  'i',  'o',  ' ',  'D',  'a',  'r', 
    'k',  ' ',  'T',  'e',  'x',  't', 
    0xff, 
};
QT_MOC_EXPORT_PLUGIN_V2(TextCreatorFactory, TextCreatorFactory, qt_pluginMetaDataV2_TextCreatorFactory)
#else
QT_PLUGIN_METADATA_SECTION
Q_CONSTINIT static constexpr unsigned char qt_pluginMetaData_TextCreatorFactory[] = {
    'Q', 'T', 'M', 'E', 'T', 'A', 'D', 'A', 'T', 'A', ' ', '!',
    // metadata version, Qt version, architectural requirements
    0, QT_VERSION_MAJOR, QT_VERSION_MINOR, qPluginArchRequirements(),
    0xbf, 
    // "IID"
    0x02,  0x76,  'o',  'r',  'g',  '.',  'k',  'd', 
    'e',  '.',  'K',  'P',  'l',  'u',  'g',  'i', 
    'n',  'F',  'a',  'c',  't',  'o',  'r',  'y', 
    // "className"
    0x03,  0x72,  'T',  'e',  'x',  't',  'C',  'r', 
    'e',  'a',  't',  'o',  'r',  'F',  'a',  'c', 
    't',  'o',  'r',  'y', 
    // "MetaData"
    0x04,  0xa2,  0x6e,  'C',  'a',  'c',  'h',  'e', 
    'T',  'h',  'u',  'm',  'b',  'n',  'a',  'i', 
    'l',  0xf4,  0x67,  'K',  'P',  'l',  'u',  'g', 
    'i',  'n',  0xa2,  0x69,  'M',  'i',  'm',  'e', 
    'T',  'y',  'p',  'e',  's',  0x81,  0x6a,  't', 
    'e',  'x',  't',  '/',  'p',  'l',  'a',  'i', 
    'n',  0x64,  'N',  'a',  'm',  'e',  0x6f,  'F', 
    'o',  'l',  'i',  'o',  ' ',  'D',  'a',  'r', 
    'k',  ' ',  'T',  'e',  'x',  't', 
    0xff, 
};
QT_MOC_EXPORT_PLUGIN(TextCreatorFactory, TextCreatorFactory)
#endif  // QT_MOC_EXPORT_PLUGIN_V2

QT_WARNING_POP
