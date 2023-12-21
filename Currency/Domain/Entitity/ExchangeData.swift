import Foundation

struct ExchangeData: Codable {
    let disclaimer: String
    let license: String
    let timestamp: TimeInterval
    let base: String
    @DictionaryWrapper var rates: [Currency: Decimal]
}

struct CurrencyDesciption: Codable {
    static let descriptions: [Currency: String] = [
        .AED: "United Arab Emirates Dirham",
        .AFN: "Afghan Afghani",
        .ALL: "Albanian Lek",
        .AMD: "Armenian Dram",
        .ANG: "Netherlands Antillean Guilder",
        .AOA: "Angolan Kwanza",
        .ARS: "Argentine Peso",
        .AUD: "Australian Dollar",
        .AWG: "Aruban Florin",
        .AZN: "Azerbaijani Manat",
        .BAM: "Bosnia-Herzegovina Convertible Mark",
        .BBD: "Barbadian Dollar",
        .BDT: "Bangladeshi Taka",
        .BGN: "Bulgarian Lev",
        .BHD: "Bahraini Dinar",
        .BIF: "Burundian Franc",
        .BMD: "Bermudan Dollar",
        .BND: "Brunei Dollar",
        .BOB: "Bolivian Boliviano",
        .BRL: "Brazilian Real",
        .BSD: "Bahamian Dollar",
        .BTC: "Bitcoin",
        .BTN: "Bhutanese Ngultrum",
        .BWP: "Botswanan Pula",
        .BYN: "Belarusian Ruble",
        .BZD: "Belize Dollar",
        .CAD: "Canadian Dollar",
        .CDF: "Congolese Franc",
        .CHF: "Swiss Franc",
        .CLF: "Chilean Unit of Account (UF)",
        .CLP: "Chilean Peso",
        .CNH: "Chinese Yuan (Offshore)",
        .CNY: "Chinese Yuan",
        .COP: "Colombian Peso",
        .CRC: "Costa Rican Colón",
        .CUC: "Cuban Convertible Peso",
        .CUP: "Cuban Peso",
        .CVE: "Cape Verdean Escudo",
        .CZK: "Czech Republic Koruna",
        .DJF: "Djiboutian Franc",
        .DKK: "Danish Krone",
        .DOP: "Dominican Peso",
        .DZD: "Algerian Dinar",
        .EGP: "Egyptian Pound",
        .ERN: "Eritrean Nakfa",
        .ETB: "Ethiopian Birr",
        .EUR: "Euro",
        .FJD: "Fijian Dollar",
        .FKP: "Falkland Islands Pound",
        .GBP: "British Pound Sterling",
        .GEL: "Georgian Lari",
        .GGP: "Guernsey Pound",
        .GHS: "Ghanaian Cedi",
        .GIP: "Gibraltar Pound",
        .GMD: "Gambian Dalasi",
        .GNF: "Guinean Franc",
        .GTQ: "Guatemalan Quetzal",
        .GYD: "Guyanaese Dollar",
        .HKD: "Hong Kong Dollar",
        .HNL: "Honduran Lempira",
        .HRK: "Croatian Kuna",
        .HTG: "Haitian Gourde",
        .HUF: "Hungarian Forint",
        .IDR: "Indonesian Rupiah",
        .ILS: "Israeli New Sheqel",
        .IMP: "Manx pound",
        .INR: "Indian Rupee",
        .IQD: "Iraqi Dinar",
        .IRR: "Iranian Rial",
        .ISK: "Icelandic Króna",
        .JEP: "Jersey Pound",
        .JMD: "Jamaican Dollar",
        .JOD: "Jordanian Dinar",
        .JPY: "Japanese Yen",
        .KES: "Kenyan Shilling",
        .KGS: "Kyrgystani Som",
        .KHR: "Cambodian Riel",
        .KMF: "Comorian Franc",
        .KPW: "North Korean Won",
        .KRW: "South Korean Won",
        .KWD: "Kuwaiti Dinar",
        .KYD: "Cayman Islands Dollar",
        .KZT: "Kazakhstani Tenge",
        .LAK: "Laotian Kip",
        .LBP: "Lebanese Pound",
        .LKR: "Sri Lankan Rupee",
        .LRD: "Liberian Dollar",
        .LSL: "Lesotho Loti",
        .LYD: "Libyan Dinar",
        .MAD: "Moroccan Dirham",
        .MDL: "Moldovan Leu",
        .MGA: "Malagasy Ariary",
        .MKD: "Macedonian Denar",
        .MMK: "Myanma Kyat",
        .MNT: "Mongolian Tugrik",
        .MOP: "Macanese Pataca",
        .MRU: "Mauritanian Ouguiya",
        .MUR: "Mauritian Rupee",
        .MVR: "Maldivian Rufiyaa",
        .MWK: "Malawian Kwacha",
        .MXN: "Mexican Peso",
        .MYR: "Malaysian Ringgit",
        .MZN: "Mozambican Metical",
        .NAD: "Namibian Dollar",
        .NGN: "Nigerian Naira",
        .NIO: "Nicaraguan Córdoba",
        .NOK: "Norwegian Krone",
        .NPR: "Nepalese Rupee",
        .NZD: "New Zealand Dollar",
        .OMR: "Omani Rial",
        .PAB: "Panamanian Balboa",
        .PEN: "Peruvian Nuevo Sol",
        .PGK: "Papua New Guinean Kina",
        .PHP: "Philippine Peso",
        .PKR: "Pakistani Rupee",
        .PLN: "Polish Zloty",
        .PYG: "Paraguayan Guarani",
        .QAR: "Qatari Rial",
        .RON: "Romanian Leu",
        .RSD: "Serbian Dinar",
        .RUB: "Russian Ruble",
        .RWF: "Rwandan Franc",
        .SAR: "Saudi Riyal",
        .SBD: "Solomon Islands Dollar",
        .SCR: "Seychellois Rupee",
        .SDG: "Sudanese Pound",
        .SEK: "Swedish Krona",
        .SGD: "Singapore Dollar",
        .SHP: "Saint Helena Pound",
        .SLL: "Sierra Leonean Leone",
        .SOS: "Somali Shilling",
        .SRD: "Surinamese Dollar",
        .SSP: "South Sudanese Pound",
        .STD: "São Tomé and Príncipe Dobra (pre-2018)",
        .STN: "São Tomé and Príncipe Dobra",
        .SVC: "Salvadoran Colón",
        .SYP: "Syrian Pound",
        .SZL: "Swazi Lilangeni",
        .THB: "Thai Baht",
        .TJS: "Tajikistani Somoni",
        .TMT: "Turkmenistani Manat",
        .TND: "Tunisian Dinar",
        .TOP: "Tongan Pa'anga",
        .TRY: "Turkish Lira",
        .TTD: "Trinidad and Tobago Dollar",
        .TWD: "New Taiwan Dollar",
        .TZS: "Tanzanian Shilling",
        .UAH: "Ukrainian Hryvnia",
        .UGX: "Ugandan Shilling",
        .USD: "United States Dollar",
        .UYU: "Uruguayan Peso",
        .UZS: "Uzbekistan Som",
        .VES: "Venezuelan Bolívar Soberano",
        .VND: "Vietnamese Dong",
        .VUV: "Vanuatu Vatu",
        .WST: "Samoan Tala",
        .XAF: "CFA Franc BEAC",
        .XAG: "Silver Ounce",
        .XAU: "Gold Ounce",
        .XCD: "East Caribbean Dollar",
        .XDR: "Special Drawing Rights",
        .XOF: "CFA Franc BCEAO",
        .XPD: "Palladium Ounce",
        .XPF: "CFP Franc",
        .XPT: "Platinum Ounce",
        .YER: "Yemeni Rial",
        .ZAR: "South African Rand",
        .ZMW: "Zambian Kwacha",
        .ZWL: "Zimbabwean Dollar",
    ]
}

struct Currency: RawRepresentable, Codable, Hashable {
    let rawValue: String

    static let AED = Currency(rawValue: "AED")
    static let AFN = Currency(rawValue: "AFN")
    static let ALL = Currency(rawValue: "ALL")
    static let AMD = Currency(rawValue: "AMD")
    static let ANG = Currency(rawValue: "ANG")
    static let AOA = Currency(rawValue: "AOA")
    static let ARS = Currency(rawValue: "ARS")
    static let AUD = Currency(rawValue: "AUD")
    static let AWG = Currency(rawValue: "AWG")
    static let AZN = Currency(rawValue: "AZN")
    static let BAM = Currency(rawValue: "BAM")
    static let BBD = Currency(rawValue: "BBD")
    static let BDT = Currency(rawValue: "BDT")
    static let BGN = Currency(rawValue: "BGN")
    static let BHD = Currency(rawValue: "BHD")
    static let BIF = Currency(rawValue: "BIF")
    static let BMD = Currency(rawValue: "BMD")
    static let BND = Currency(rawValue: "BND")
    static let BOB = Currency(rawValue: "BOB")
    static let BRL = Currency(rawValue: "BRL")
    static let BSD = Currency(rawValue: "BSD")
    static let BTC = Currency(rawValue: "BTC")
    static let BTN = Currency(rawValue: "BTN")
    static let BWP = Currency(rawValue: "BWP")
    static let BYN = Currency(rawValue: "BYN")
    static let BZD = Currency(rawValue: "BZD")
    static let CAD = Currency(rawValue: "CAD")
    static let CDF = Currency(rawValue: "CDF")
    static let CHF = Currency(rawValue: "CHF")
    static let CLF = Currency(rawValue: "CLF")
    static let CLP = Currency(rawValue: "CLP")
    static let CNH = Currency(rawValue: "CNH")
    static let CNY = Currency(rawValue: "CNY")
    static let COP = Currency(rawValue: "COP")
    static let CRC = Currency(rawValue: "CRC")
    static let CUC = Currency(rawValue: "CUC")
    static let CUP = Currency(rawValue: "CUP")
    static let CVE = Currency(rawValue: "CVE")
    static let CZK = Currency(rawValue: "CZK")
    static let DJF = Currency(rawValue: "DJF")
    static let DKK = Currency(rawValue: "DKK")
    static let DOP = Currency(rawValue: "DOP")
    static let DZD = Currency(rawValue: "DZD")
    static let EGP = Currency(rawValue: "EGP")
    static let ERN = Currency(rawValue: "ERN")
    static let ETB = Currency(rawValue: "ETB")
    static let EUR = Currency(rawValue: "EUR")
    static let FJD = Currency(rawValue: "FJD")
    static let FKP = Currency(rawValue: "FKP")
    static let GBP = Currency(rawValue: "GBP")
    static let GEL = Currency(rawValue: "GEL")
    static let GGP = Currency(rawValue: "GGP")
    static let GHS = Currency(rawValue: "GHS")
    static let GIP = Currency(rawValue: "GIP")
    static let GMD = Currency(rawValue: "GMD")
    static let GNF = Currency(rawValue: "GNF")
    static let GTQ = Currency(rawValue: "GTQ")
    static let GYD = Currency(rawValue: "GYD")
    static let HKD = Currency(rawValue: "HKD")
    static let HNL = Currency(rawValue: "HNL")
    static let HRK = Currency(rawValue: "HRK")
    static let HTG = Currency(rawValue: "HTG")
    static let HUF = Currency(rawValue: "HUF")
    static let IDR = Currency(rawValue: "IDR")
    static let ILS = Currency(rawValue: "ILS")
    static let IMP = Currency(rawValue: "IMP")
    static let INR = Currency(rawValue: "INR")
    static let IQD = Currency(rawValue: "IQD")
    static let IRR = Currency(rawValue: "IRR")
    static let ISK = Currency(rawValue: "ISK")
    static let JEP = Currency(rawValue: "JEP")
    static let JMD = Currency(rawValue: "JMD")
    static let JOD = Currency(rawValue: "JOD")
    static let JPY = Currency(rawValue: "JPY")
    static let KES = Currency(rawValue: "KES")
    static let KGS = Currency(rawValue: "KGS")
    static let KHR = Currency(rawValue: "KHR")
    static let KMF = Currency(rawValue: "KMF")
    static let KPW = Currency(rawValue: "KPW")
    static let KRW = Currency(rawValue: "KRW")
    static let KWD = Currency(rawValue: "KWD")
    static let KYD = Currency(rawValue: "KYD")
    static let KZT = Currency(rawValue: "KZT")
    static let LAK = Currency(rawValue: "LAK")
    static let LBP = Currency(rawValue: "LBP")
    static let LKR = Currency(rawValue: "LKR")
    static let LRD = Currency(rawValue: "LRD")
    static let LSL = Currency(rawValue: "LSL")
    static let LYD = Currency(rawValue: "LYD")
    static let MAD = Currency(rawValue: "MAD")
    static let MDL = Currency(rawValue: "MDL")
    static let MGA = Currency(rawValue: "MGA")
    static let MKD = Currency(rawValue: "MKD")
    static let MMK = Currency(rawValue: "MMK")
    static let MNT = Currency(rawValue: "MNT")
    static let MOP = Currency(rawValue: "MOP")
    static let MRU = Currency(rawValue: "MRU")
    static let MUR = Currency(rawValue: "MUR")
    static let MVR = Currency(rawValue: "MVR")
    static let MWK = Currency(rawValue: "MWK")
    static let MXN = Currency(rawValue: "MXN")
    static let MYR = Currency(rawValue: "MYR")
    static let MZN = Currency(rawValue: "MZN")
    static let NAD = Currency(rawValue: "NAD")
    static let NGN = Currency(rawValue: "NGN")
    static let NIO = Currency(rawValue: "NIO")
    static let NOK = Currency(rawValue: "NOK")
    static let NPR = Currency(rawValue: "NPR")
    static let NZD = Currency(rawValue: "NZD")
    static let OMR = Currency(rawValue: "OMR")
    static let PAB = Currency(rawValue: "PAB")
    static let PEN = Currency(rawValue: "PEN")
    static let PGK = Currency(rawValue: "PGK")
    static let PHP = Currency(rawValue: "PHP")
    static let PKR = Currency(rawValue: "PKR")
    static let PLN = Currency(rawValue: "PLN")
    static let PYG = Currency(rawValue: "PYG")
    static let QAR = Currency(rawValue: "QAR")
    static let RON = Currency(rawValue: "RON")
    static let RSD = Currency(rawValue: "RSD")
    static let RUB = Currency(rawValue: "RUB")
    static let RWF = Currency(rawValue: "RWF")
    static let SAR = Currency(rawValue: "SAR")
    static let SBD = Currency(rawValue: "SBD")
    static let SCR = Currency(rawValue: "SCR")
    static let SDG = Currency(rawValue: "SDG")
    static let SEK = Currency(rawValue: "SEK")
    static let SGD = Currency(rawValue: "SGD")
    static let SHP = Currency(rawValue: "SHP")
    static let SLL = Currency(rawValue: "SLL")
    static let SOS = Currency(rawValue: "SOS")
    static let SRD = Currency(rawValue: "SRD")
    static let SSP = Currency(rawValue: "SSP")
    static let STD = Currency(rawValue: "STD")
    static let STN = Currency(rawValue: "STN")
    static let SVC = Currency(rawValue: "SVC")
    static let SYP = Currency(rawValue: "SYP")
    static let SZL = Currency(rawValue: "SZL")
    static let THB = Currency(rawValue: "THB")
    static let TJS = Currency(rawValue: "TJS")
    static let TMT = Currency(rawValue: "TMT")
    static let TND = Currency(rawValue: "TND")
    static let TOP = Currency(rawValue: "TOP")
    static let TRY = Currency(rawValue: "TRY")
    static let TTD = Currency(rawValue: "TTD")
    static let TWD = Currency(rawValue: "TWD")
    static let TZS = Currency(rawValue: "TZS")
    static let UAH = Currency(rawValue: "UAH")
    static let UGX = Currency(rawValue: "UGX")
    static let USD = Currency(rawValue: "USD")
    static let UYU = Currency(rawValue: "UYU")
    static let UZS = Currency(rawValue: "UZS")
    static let VES = Currency(rawValue: "VES")
    static let VND = Currency(rawValue: "VND")
    static let VUV = Currency(rawValue: "VUV")
    static let WST = Currency(rawValue: "WST")
    static let XAF = Currency(rawValue: "XAF")
    static let XAG = Currency(rawValue: "XAG")
    static let XAU = Currency(rawValue: "XAU")
    static let XCD = Currency(rawValue: "XCD")
    static let XDR = Currency(rawValue: "XDR")
    static let XOF = Currency(rawValue: "XOF")
    static let XPD = Currency(rawValue: "XPD")
    static let XPF = Currency(rawValue: "XPF")
    static let XPT = Currency(rawValue: "XPT")
    static let YER = Currency(rawValue: "YER")
    static let ZAR = Currency(rawValue: "ZAR")
    static let ZMW = Currency(rawValue: "ZMW")
    static let ZWL = Currency(rawValue: "ZWL")
}
