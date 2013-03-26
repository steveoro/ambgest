require 'singleton'

#
# == FixtureGenerator: random data generator for names, numbers and nouns.
#
# A quick and dirty singleton factory class with some utility methods for easily populating
# fixture data files or database rows.
#
# Adapted from old C code, (p) 1991-2008, FASAR Software, Italy
#
class FixtureGenerator
  include Singleton

  # Locale code
  LOCALE_IT = 1

  # Locale code
  LOCALE_US = 0
  #-----------------------------------------------------------------------------
  #++

  # String containing all possible vowel characters.
  #
  @@VOWEL = 'aeiouy'

  # Array distribution containing all groups of characters used at the start of a noun or a name.
  #
  @@START_GROUP = [
    'b','c','d','f','g','h','j','k','l','m','n','p','q','qu','r','s','t','v','w','x','z',
    'gh',
    'gr',
    'sb','sc','sd','sf','sg','sgh','sk','sl','sm','sn','sp','sq','squ','sr','st','sv','sw',
    'tl','tr'
  ]

  # Array distribution containing all groups of characters used in the middle of a noun or a name.
  #
  @@MIDDLE_GROUP = [
    'b','c','d','f','g','h','j','k','l','m','n','p','q','qu','r','s','t','v','w','x','z',
    'b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v',
    'b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v',
    'bb','cc','dd','ff','gg','gh','ll','mb','mm','nn','pp','cq','cqu','rr','ss','tt','vv','zz',
    'bd','ck',
    'lb','ld','lm',
    'mp','lgh','ld','gr',
    'nc','nch','nd','nf','ng','ngh','nj','nk','nr','ns','nt','nv','nw','nz',
    'sb','sc','sd','sf','sg','sgh','sk','sl','sm','sn','sp','sq','squ','sr','st','sv','sw',
    'tl','tr'
  ]

  # Array of common italian names.
  # If a name ends with a capital letter (usually 'O'), then it can NOT be changed to its
  # female counterpart - which is obtained substituting the ending vowel with an 'A'.
  # If a name ends with the '*' wildcard, then it can be composed with any other name in the array.
  #
  @@NAMES_IT = [                                    # 'A'
      "Andrea",      "Alberto",    "Anna*",         "AbramO",      "Achille",    "Ada*",
      "Adalgisa",    "AdamO",      "Adele",         "Adolfo",      "Adriano",    "Agata",
      "Agenore",     "AgesilaO",   "Agnese",        "Augusto",     "Agostino",   "Adria",
      "Albino",      "Alceste",    "Alcide",        "Aldo*",       "Alessandro", "Alessio",
      "Alfonso",     "Aldino",     "Alfonsino",     "Adelino",     "Andreino",   "Alice",
      "Amalia",      "Amelia",     "Ambrogio",      "Amedeo",      "Amerigo",    "Amilcare",
      "Amos",        "Anacleto",   "Anastasio",     "Angelico",    "Angelo",     "Angiolino",
      "Anselmo",     "Antonio",    "Arduino",       "Arianna",     "Aristide",   "Armando",
      "Arnoldo",     "Arnaldo",    "Arnoldino",     "Antonino",    "Aroldo",     "Arturo",
      "Atanasio",    "Attilio",    "Aureliano",     "AureliO",     "Asdrubale",  "Anselimo",
                                                    # 'B'
      "Baldassarre", "Baldovino",  "Barbara",       "Barbarella",  "Barnaba",    "Bartolomeo",
      "BasiliO",     "Battista",   "Beatrice",      "Benedetto",   "Beniamino",  "Benigno",
      "Berenice",    "Bernardo",   "Berto",         "Bertoldo",    "Bertoldino", "BiagiO",
      "Biagino",     "Bianca",     "BonifaciO",     "Brigida",     "Brigitta",   "Bruno*",
      "Beppe",       "Beppino",    "Brunella",
                                                    # 'C'
      "Calimero",    "CallistO",   "Camillo",       "Carlo*",      "Casimiro",   "Caterina",
      "CatullO",     "Cecilio",    "Celeste",       "Cesare",      "Cipriano",   "CiriacO",
      "Chiara",      "CirO",       "Claudio",       "Clelia",      "Cleofe",     "Clemente",
      "Cleopatra",   "Clotilde",   "Corinna",       "CorradO",     "CosimO",     "Costante",
      "Cristiano",   "Cristina",   "CristoforO",
                                                    # 'D'
      "Damiano",     "Daniele",    "Daniela",       "Dario",       "Davide",     "DemetriO",
      "Demetra",     "DesideriO",  "Diana",         "DiannO",      "DiegO",      "Dionigi",
      "DionisO",     "Dolores",    "DomenicO",      "Doroteo",     "Dennis",     "Denise",
                                                    # 'E'
      "Ebe*",        "Edmondo",    "Editta",        "Edvige",      "EgidiO",     "EgistO",
      "Elena",       "Eleonora",   "EliO",          "Elisabetta",  "EliseO",     "Elisa",
      "Emilio",      "Emma",       "Enrico",        "Ercole",      "ErmannO",    "Ermenegildo",
      "Ermete",      "Ernesto",    "Ester",         "Ettore",      "Eugenio",    "Eusebio",
      "Eva*",        "EziO*",      "Ernestino",
                                                    # 'F'
      "FabiO*",      "Fabiana",    "Fabrizio",      "Fausto",      "FebO*",      "Federico",
      "Felice",      "Ferdinando", "Filiberto",     "Filippo",     "Filomena",   "Fiorenzo",
      "Flavio",      "Francesco",  "Fulvio",
                                                    # 'G'
      "Gabriele",    "Gaetano",    "GaleazzO",      "Gastone",     "Gaudenzio",  "Gaia*",
      "Geltrude",    "GennarO",    "Genoveffa",     "GerardO",     "Geremia",    "GermanO",
      "GerolamO",    "GervasiO",   "GiacomO",       "Giacomino",   "GilbertO",   "GioacchinO",
      "Giorgio",     "Giosue\'",    "Giovanni",      "Giovanna",    "Giovannino", "Gianni",
      "Gianna",      "Gisella",    "Giuditta",      "Giulio",      "Giuseppe",   "GlaucO*",
      "GoffredO",    "Grazia",     "Graziella",     "Gregorio",    "GualtierO",  "Guerrino",
      "GuglielmO",   "GuidO*",     "Gustavo",       "Gian*",
                                                    # 'I'
      "Ida*",        "Igino",       "IgnaziO",      "InnocenzO",   "Iolanda",     "Iole*",
      "Ippolito",    "Irene",       "Irma*",        "Isidoro",     "Ilena",       "Iris",
                                                    # 'L'
      "Lamberto",    "LanfrancO",   "LazzarO",      "Leo*",        "Leonardo",    "Leopoldo",
      "Lia*",        "Livio",       "Lodovico",     "Luigi",       "Ludovico",    "Lorenzo",
      "Luca*",       "Lucia",       "Luciano",      "Luisa",       "Luigino",     "Leobaldo",
                                                    # 'M'
      "Maddalena",   "MarcO*",      "Margherita",   "Mario*",      "Marta",       "Marino",
      "Martino",     "MassimO",     "Matilde",      "MatteO",      "Mauro*",      "Maurizio",
      "Michele",     "Michela",     "Miranda",      "Mirella",     "Mariangelo",  "Monica",
      "Michelino",   "Massimiliano","Marialuisa",
                                                    # 'N'
      "Natale",      "Natalia",     "Natalino",     "NazarO",      "Nicola",      "Nicoletta",
      "Noemi",       "Norma*",      "NorbertO",     "Niccolo\'",
                                                    # 'O'
      "Oddone",      "Odette",      "Odetta",       "OlivierO",    "OnestO",      "Oreste",
      "OrlandO",     "Orsola",      "Oscar",        "Osvaldo",     "Onestina",    "Orsula",
      "Ottone",      "Omar",        "Olivia",
                                                    # 'P'-'Q'
      "Pacifico",    "Palmiro",     "PancraziO",    "Paolo",       "Pasqua",      "Patrizio",
      "Pericle",     "PietrO",      "Piero",        "Pier*",       "Pio*",        "Placido",
      "Pompeo",      "Porfirio",    "PrimO",        "Prospero",    "Prudenzio",   "Pino*",
      "QuintO",      "QuintinO",
                                                    # 'R'
      "Rachele",     "Raffaele",    "Raffaello",    "Raimondo",    "Ranieri",     "Rebecca",
      "Regina",      "RemigiO",     "Renato",       "RiccardO",    "RinaldO",     "Roberto",
      "Rodolfo",     "RoccO*",      "RodrigO",      "Romano",      "RomeO",       "Romualdo",
      "Rosa*",       "Rosalba",     "Rosmunda",     "Rosamunda",   "RufO*",       "RufinO",
      "RuggerO",     "Riccardino",  "Robertino",
                                                    # 'S'
      "Sabino",      "Salomone",    "Salvatore",    "Samuele",     "Samuela",     "Sara",
      "Saul",        "Saverio",     "Sebastiano",   "Serafino",    "SergiO",      "SigfridO",
      "SigismondO",  "Silvano",     "Silvio",       "Simeone",     "Simone",      "Simona",
      "SimpliciO",   "Sofia",       "StanislaO",    "StefanO",     "Susanna",     "Simonetta",
                                                    # 'T'
      "TaddeO",      "Temistocle",  "TeodoricO",    "Teodoro",     "Teodosio",    "Terenzio",
      "Teresa",      "TimoteO",     "TitO*",        "TommasO",     "TulliO",      "Teresina",
                                                    # 'U'
      "Ubaldo",      "Uberto",      "Umberto",      "Ugo*",        "Ulrico",      "Ulisse",
      "UrbanO",      "UmbertinO",   "Ulrich",
                                                    # 'V'
      "Valentino",   "Venanzio",    "Veneranda",    "Vera",        "Veronica",    "VigiliO",
      "Vincenzo",    "Virgilio",    "Vitale",       "Vittore",     "Vittorio",    "Vladimiro",
                                                    # 'W'
      "Walter",      "Wainer",      "Wanda",        "Werter",
                                                    # 'Z'
      "Zaccaria",    "Zaira",       "ZenO",         "Zenobio",     "Zoe",         "Zora",
      "ZoroastrO"
  ]

  # Array of conjunctions and articles, locale = IT (simplyfied version)
  @@CONJ_IT = [
      'di','a','da','in','con','su','per','tra','fra',
      'dai','ai','coi','sui','per i','tra i', 'fra i',
      'al','dal','col','sul','per il','tra il','fra il',
      'del','della','dei'
  ]

  # Array of conjunctions and articles, locale = US (simplyfied version)
  @@CONJ_US = [
      'of','to','from','in','with','on','for',
      'of the','to the','from the','in the','with the','on the','for the'
  ]

  # Array of articles, locale = IT
  @@ARTICLE_IT = [ 'i', 'il','un' ]

  # Array of articles, locale = US
  @@ARTICLE_US = [ 'the','a' ]

  # Array of address prefixes, locale = IT
  @@ADDRESS_IT = [
      'Piazza','Largo','Via','Strada','Via','Stretto','Vicolo','Via','Statale','Via',"Localita\'"
  ]

  # Array of address prefixes, locale = IT
  @@ADDRESS_US = [
      'Plaza','Street','Road','Street','Road''Street','Crossway','Road','Highway'
  ]
  #-----------------------------------------------------------------------------
  #++

  # Generates a random vowel, excluding the specified characters.
  #
  def self.get_vowel( exclude_chars = '' )
    s = @@VOWEL.delete(exclude_chars)

    s[ rand(s.size), 1 ]
  end

  # Generates a random group of characters used at the start of a noun or a name.
  #
  def self.get_starting_group( use_only_latin_chars = true )
    arr = use_only_latin_chars ? @@START_GROUP.collect {|e| e.delete('xywjk') } - [''] : @@START_GROUP

    arr[ rand(arr.size) ]
  end

  # Generates a random group of characters used in the middle of a noun or a name.
  #
  def self.get_middle_group( use_only_latin_chars = true )
    arr = use_only_latin_chars ? @@MIDDLE_GROUP.collect {|e| e.delete('xywjk') } - [''] : @@MIDDLE_GROUP

    arr[ rand(arr.size) ]
  end
  #-----------------------------------------------------------------------------
  #++

  # Generates a random conjunction, given a supported locale code.
  #
  def self.get_conjunction( locale = LOCALE_IT )
    case locale
    when LOCALE_IT
      arr = @@CONJ_IT
#    when LOCALE_US
    # TODO Support for more locales
    else
      arr = @@CONJ_US
    end

    arr[ rand(arr.size) ]
  end

  # Generates a random article, given a supported locale code.
  #
  def self.get_article( locale = LOCALE_IT )
    case locale
    when LOCALE_IT
      arr = @@ARTICLE_IT
#    when LOCALE_US
    # TODO Support for more locales
    else
      arr = @@ARTICLE_US
    end

    arr[ rand(arr.size) ]
  end

  # Generates a random address "title" (prefix or postfix, like "Street"), given a supported locale code.
  #
  def self.get_address_title( locale = LOCALE_IT )
    case locale
    when LOCALE_IT
      arr = @@ADDRESS_IT
#    when LOCALE_US
    # TODO Support for more locales
    else
      arr = @@ADDRESS_US
    end

    arr[ rand(arr.size) ]
  end
  #-----------------------------------------------------------------------------
  #++

  # Generate a single randomized string text with a length of _at_least_ +iMinLength+ characters.
  # The actual size of the generated noun can vary in between: <tt>iMinLength <= x <= iMinLength + 3</tt>
  #
  def self.random_noun( iMinLength = 5, use_only_latin_chars = true )
    result = ''
    choice = ''
    srand
    i=0

    while (i <= iMinLength)
      if (i == 0)
        if (rand >= 0.5)
          choice = self.get_vowel( use_only_latin_chars ? 'y' : '' ).capitalize
        else
          choice = self.get_starting_group(use_only_latin_chars).capitalize
          choice << self.get_vowel( choice[choice.size-1,1] + (use_only_latin_chars ? 'y' : '')  )
        end
      else
        choice = self.get_middle_group(use_only_latin_chars)
        choice << self.get_vowel( choice[choice.size-1,1] + (use_only_latin_chars ? 'y' : '') )
      end
# DEBUG:
#      puts "Adding #{choice}..."
      result << choice
      i = i + choice.size
      choice = ''
    end

    result
  end
  #-----------------------------------------------------------------------------
  #++

  # Generate a single randomized integer string of a given length in characters
  #
  def self.random_number( iLength = 4 )
    result = ''
    srand
    iLength.times { result << rand(10).to_s } if iLength >= 0

    result
  end

  # Generate a single randomized (pseudo) phone number of a given length in characters
  #
  def self.random_phone( iLength = 10, sSeparator = '.' )
    result = ''
    srand

    for i in 1..iLength
      result << rand(10).to_s
      result << sSeparator if (i == 3 && iLength > 3) || (i == 7 && iLength > 8) ||
                              (i == 10 && iLength > 11) || (i == 15 && iLength > 16)
    end

    result
  end
  #-----------------------------------------------------------------------------
  #++

  # Changes a name to its male or female counterpart, given a supported locale code.
  # The result is also stripped of the special ending character.
  # Does nothing for unsupported locale strings.
  #
  def self.fix_gender( a_name, change_to_male = false, locale = LOCALE_IT )
    result = a_name

    if locale == LOCALE_IT
      if a_name[a_name.size-1, 1] == 'O'
        result = a_name.capitalize                  # (cannot change)
      elsif ['a','o'].include?( a_name[a_name.size-1, 1] )
        result = a_name[0, a_name.size-1] + (change_to_male ? 'o' : 'a')
      end
#    else
    # TODO Support for more locales
    end
    result
  end

  # Processes a name for randomized gender change, given a supported locale code.
  # The result is also stripped of the special ending character.
  # Does nothing for unsupported locale strings.
  #
  def self.random_gender( a_name, locale = LOCALE_IT )
    srand
    self.fix_gender( a_name, (rand >= 0.5), locale )
  end

  # Changes a name to a composed one when possible, given a supported locale code.
  # The result is also stripped of the special ending character.
  # Does nothing for unsupported locale strings or if the name does not end with the special wildcard '*'.
  #
  def self.fix_composed_name( a_name, locale = LOCALE_IT )
    result = a_name

    if locale == LOCALE_IT
      if a_name[a_name.size-1, 1] == '*'
        result = self.random_gender(a_name[0, a_name.size-1], locale) +
                 (rand >= 0.5 ? self.random_name() : '')
      end
#    else
    # TODO Support for more locales
    end
    result
  end

  # Generate a single randomized name, given a supported locale code.
  #
  def self.random_name( iMinLength = 4, locale = LOCALE_IT )
    result = ''
    srand

    if locale == LOCALE_IT
      r = rand(@@NAMES_IT.size)
      result = @@NAMES_IT[r]
                                                    # Change to male | female occasionally, when possible:
      result = self.random_gender(                  # Check and fix, also, if the name can be composed:
                  self.fix_composed_name( result, locale ),
                  locale
      )
    # TODO Support for more locales
    else
      result = self.random_noun( iMinLength, false )
    end
    result
  end
  #-----------------------------------------------------------------------------
  #++

  # Generate a single randomized person name, given a minimum length.
  #
  def self.random_person( iMinLength = 4, locale = LOCALE_IT )
    self.random_name( iMinLength, locale ) + ' ' +
    self.random_noun( iMinLength + (rand >= 0.5 ? rand(4) : -rand(1)), (locale==LOCALE_IT) )
  end
  #-----------------------------------------------------------------------------
  #++

  # Generate a single random pseudo sentence, given a minimum length.
  #
  def self.random_sentence( iMinLength = 40, locale = LOCALE_IT )
    result = ''
    srand

    while result.size < iMinLength
      noun = self.random_noun( 5 + rand(3)-1, (locale==LOCALE_IT) )
      conj = self.get_conjunction(locale)
      result << ' ' if result.size > 0 && result.size < iMinLength
      result << noun if result.size < iMinLength
      result << ' ' << conj if result.size + conj.size + noun.size + 2 < iMinLength
    end

    result.strip
  end
  #-----------------------------------------------------------------------------
  #++

  # Generate a single random pseudo address, given a minimum length.
  #
  def self.random_address( iMinLength = 30, locale = LOCALE_IT )
    street_title = self.get_address_title(locale)
    result = self.random_sentence( iMinLength - street_title.size - 1, locale )

    case locale
    when LOCALE_IT
      result = '' << street_title << ' ' << result
#    when LOCALE_US
    # TODO Support for more locales
    else
      result << ' ' << street_title
    end

    result
  end
  #-----------------------------------------------------------------------------
  #++
end
