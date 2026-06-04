
import Foundation

struct QuizData {
    static let questions: [QuizQuestion] = [
        QuizQuestion(text: "Who was the top scorer in the 2002 World Cup?", options: ["Ronaldo", "Rivaldo", "Klose"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country has won the most World Cups?", options: ["Germany", "Brazil", "Italy"], correctOptionIndex: 1),
        QuizQuestion(text: "Who won the World Cup in 2018?", options: ["Croatia", "France", "Belgium"], correctOptionIndex: 1),
        QuizQuestion(text: "Which player scored the 'Hand of God' goal?", options: ["Pele", "Maradona", "Zico"], correctOptionIndex: 1),
        QuizQuestion(text: "In which year was the first World Cup held?", options: ["1926", "1930", "1934"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Who won the Golden Boot in 2014?", options: ["James Rodriguez", "Thomas Muller", "Messi"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 2010 World Cup?", options: ["South Africa", "Brazil", "Germany"], correctOptionIndex: 0),
        QuizQuestion(text: "Who is the all-time top scorer in World Cup history?", options: ["Ronaldo", "Klose", "Fontaine"], correctOptionIndex: 1),
        QuizQuestion(text: "Which country won the first World Cup?", options: ["Uruguay", "Argentina", "Brazil"], correctOptionIndex: 0),
        QuizQuestion(text: "What was the official mascot of the 1998 World Cup?", options: ["Footix", "Ciao", "Striker"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which team did France defeat in the 1998 final?", options: ["Brazil", "Italy", "Germany"], correctOptionIndex: 0),
        QuizQuestion(text: "In which country was the 2006 World Cup held?", options: ["Germany", "France", "Italy"], correctOptionIndex: 0),
        QuizQuestion(text: "Who scored the winning goal in the 2010 final?", options: ["Xavi", "Iniesta", "Villa"], correctOptionIndex: 1),
        QuizQuestion(text: "Which player has the most World Cup appearances?", options: ["Messi", "Matthäus", "Maldini"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the Golden Ball in 2014?", options: ["Messi", "Neur", "Robben"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which African team reached the semi-finals in 2022?", options: ["Senegal", "Morocco", "Ghana"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the coach of Spain in 2010?", options: ["Del Bosque", "Aragones", "Guardiola"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country was runner-up in 2014?", options: ["Brazil", "Netherlands", "Argentina"], correctOptionIndex: 2),
        QuizQuestion(text: "Who scored 13 goals in a single World Cup?", options: ["Just Fontaine", "Gerd Muller", "Ronaldo"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1994 World Cup?", options: ["Mexico", "USA", "France"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Who won the 1986 World Cup?", options: ["Argentina", "Germany", "Italy"], correctOptionIndex: 0),
        QuizQuestion(text: "Which player headbutted Materazzi in 2006?", options: ["Henry", "Viera", "Zidane"], correctOptionIndex: 2),
        QuizQuestion(text: "Who was the top scorer in 2018?", options: ["Harry Kane", "Mbappe", "Griezmann"], correctOptionIndex: 0),
        QuizQuestion(text: "Which team eliminated Brazil in 2014 with a 7-1 score?", options: ["Netherlands", "Germany", "Argentina"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the youngest player to win a World Cup?", options: ["Pele", "Mbappe", "Ronaldo"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which country has appeared in every World Cup?", options: ["Germany", "Argentina", "Brazil"], correctOptionIndex: 2),
        QuizQuestion(text: "Who was the captain of France in 1998?", options: ["Zidane", "Deschamps", "Blanc"], correctOptionIndex: 1),
        QuizQuestion(text: "Who won the Golden Glove in 2018?", options: ["Courtois", "Lloris", "Pickford"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country won in 1966?", options: ["Germany", "England", "Brazil"], correctOptionIndex: 1),
        QuizQuestion(text: "Who scored the fastest goal in World Cup history?", options: ["Hakan Sukur", "Dempsey", "Vava"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which team did Italy defeat in 2006 final?", options: ["Germany", "France", "Portugal"], correctOptionIndex: 1),
        QuizQuestion(text: "Who won the Golden Ball in 2018?", options: ["Modric", "Mbappe", "Hazard"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 2002 World Cup?", options: ["Japan", "South Korea", "Both"], correctOptionIndex: 2),
        QuizQuestion(text: "Who was the coach of Brazil in 2002?", options: ["Scolari", "Parreira", "Zagallo"], correctOptionIndex: 0),
        QuizQuestion(text: "Which team won the 1978 World Cup?", options: ["Argentina", "Netherlands", "Brazil"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Who missed the crucial penalty for Italy in 1994?", options: ["Baresi", "Maldini", "Baggio"], correctOptionIndex: 2),
        QuizQuestion(text: "Which country has won 4 World Cups?", options: ["France", "Argentina", "Germany"], correctOptionIndex: 2),
        QuizQuestion(text: "Who was top scorer in 1998?", options: ["Suker", "Ronaldo", "Vieri"], correctOptionIndex: 0),
        QuizQuestion(text: "Which nation hosted the 1970 World Cup?", options: ["Mexico", "England", "Brazil"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the World Cup in 1950?", options: ["Uruguay", "Brazil", "Sweden"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Who scored the winning goal for Germany in 2014?", options: ["Muller", "Gotze", "Klose"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the Golden Ball winner in 2002?", options: ["Ronaldo", "Kahn", "Rivaldo"], correctOptionIndex: 1),
        QuizQuestion(text: "Which player has scored in 4 different World Cups?", options: ["Ronaldo", "Klose", "Both"], correctOptionIndex: 2),
        QuizQuestion(text: "Which team came 3rd in 2018?", options: ["England", "Belgium", "Croatia"], correctOptionIndex: 1),
        QuizQuestion(text: "Who managed Argentina in 2022?", options: ["Scaloni", "Sampaoli", "Sabella"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which country hosted the 1934 World Cup?", options: ["Italy", "France", "Uruguay"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the Golden Boot in 2010?", options: ["Snijder", "Villa", "Muller"], correctOptionIndex: 2),
        QuizQuestion(text: "Who was the captain of Brazil in 2002?", options: ["Cafu", "Ronaldo", "Lucio"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country did Pele play for?", options: ["Argentina", "Portugal", "Brazil"], correctOptionIndex: 2),
        QuizQuestion(text: "Who won the 1982 World Cup?", options: ["Germany", "Italy", "France"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Which team lost the final in 2010?", options: ["Germany", "Netherlands", "Uruguay"], correctOptionIndex: 1),
        QuizQuestion(text: "Who scored a hat-trick in the 2022 final?", options: ["Messi", "Mbappe", "Alvarez"], correctOptionIndex: 1),
        QuizQuestion(text: "Which country hosted the 1958 World Cup?", options: ["Switzerland", "Sweden", "Chile"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the top scorer in 2006?", options: ["Klose", "Crespo", "Ronaldo"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country won the 1990 World Cup?", options: ["Argentina", "West Germany", "Italy"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Who was the youngest goalscorer in World Cup history?", options: ["Owen", "Pele", "Messi"], correctOptionIndex: 1),
        QuizQuestion(text: "Which team reached the final in 2018?", options: ["Croatia", "Belgium", "England"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the Golden Glove in 2022?", options: ["Martinez", "Lloris", "Bounou"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country has reached the most finals?", options: ["Brazil", "Germany", "Italy"], correctOptionIndex: 1),
        QuizQuestion(text: "Who scored the opening goal of the 2010 World Cup?", options: ["Tshabalala", "Marquez", "Suarez"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which team did Spain beat in the 2010 final?", options: ["Germany", "Netherlands", "Uruguay"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the coach of Germany in 2014?", options: ["Klinsmann", "Low", "Flick"], correctOptionIndex: 1),
        QuizQuestion(text: "Which player has the most World Cup goals for England?", options: ["Lineker", "Kane", "Rooney"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the Best Young Player award in 2018?", options: ["Mbappe", "Pavard", "Sterling"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1978 World Cup?", options: ["Argentina", "Spain", "Mexico"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Who scored for England in the 1966 final (hat-trick)?", options: ["Charlton", "Hurst", "Peters"], correctOptionIndex: 1),
        QuizQuestion(text: "Which team finished 3rd in 2014?", options: ["Brazil", "Netherlands", "Germany"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the top scorer for Brazil in 2002?", options: ["Rivaldo", "Ronaldo", "Ronaldinho"], correctOptionIndex: 1),
        QuizQuestion(text: "Who won the 1974 World Cup?", options: ["West Germany", "Netherlands", "Poland"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1982 World Cup?", options: ["Spain", "Italy", "Mexico"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Who was sent off in the 2006 final?", options: ["Materazzi", "Trezeguet", "Zidane"], correctOptionIndex: 2),
        QuizQuestion(text: "Which team did Argentina beat in 1986 final?", options: ["West Germany", "England", "Belgium"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the Golden Ball in 2010?", options: ["Forlan", "Sneijder", "Villa"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1962 World Cup?", options: ["Chile", "Brazil", "Sweden"], correctOptionIndex: 0),
        QuizQuestion(text: "Who scored the goal of the tournament in 2014?", options: ["James Rodriguez", "Van Persie", "Gotze"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Which team eliminated Spain in 2018?", options: ["Russia", "Portugal", "Morocco"], correctOptionIndex: 0),
        QuizQuestion(text: "Who was the captain of Italy in 2006?", options: ["Buffon", "Cannavaro", "Totti"], correctOptionIndex: 1),
        QuizQuestion(text: "Which country won the 1938 World Cup?", options: ["Hungary", "Italy", "Brazil"], correctOptionIndex: 1),
        QuizQuestion(text: "Who scored the winning goal in 2002 final?", options: ["Ronaldo", "Rivaldo", "Kleberson"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1990 World Cup?", options: ["USA", "Italy", "France"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Who won the Golden Boot in 1986?", options: ["Maradona", "Lineker", "Careca"], correctOptionIndex: 1),
        QuizQuestion(text: "Which team finished 4th in 2018?", options: ["England", "Belgium", "France"], correctOptionIndex: 0),
        QuizQuestion(text: "Who was the goalkeeper for Spain in 2010?", options: ["Casillas", "Reina", "Valdes"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country won the 1954 World Cup?", options: ["Hungary", "West Germany", "Austria"], correctOptionIndex: 1),
        QuizQuestion(text: "Who scored the fastest hat-trick in World Cup history?", options: ["Batistuta", "Kiss", "Pele"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Which team did France beat in 2018 final?", options: ["Belgium", "Croatia", "England"], correctOptionIndex: 1),
        QuizQuestion(text: "Who won the Best Young Player award in 2014?", options: ["Pogba", "Varane", "Depay"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1986 World Cup?", options: ["Colombia", "Mexico", "USA"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the captain of Argentina in 1986?", options: ["Maradona", "Passarella", "Valdano"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country won the 1930 World Cup?", options: ["Argentina", "Uruguay", "USA"], correctOptionIndex: 1),
        
        QuizQuestion(text: "Who scored the 'Century Goal'?", options: ["Pele", "Maradona", "Cruyff"], correctOptionIndex: 1),
        QuizQuestion(text: "Which team eliminated Germany in 2018 Group Stage?", options: ["Mexico", "Sweden", "South Korea"], correctOptionIndex: 2),
        QuizQuestion(text: "Who won the Golden Boot in 2002?", options: ["Ronaldo", "Klose", "Rivaldo"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1954 World Cup?", options: ["Switzerland", "Sweden", "France"], correctOptionIndex: 0),
        QuizQuestion(text: "Who was the top scorer in 1994?", options: ["Romario", "Stoichkov", "Salenko"], correctOptionIndex: 2), // Actually shared Stoichkov/Salenko
        
        QuizQuestion(text: "Which team did Brazil beat in 1994 final?", options: ["Italy", "Sweden", "Bulgaria"], correctOptionIndex: 0),
        QuizQuestion(text: "Who won the Golden Ball in 1998?", options: ["Zidane", "Ronaldo", "Suker"], correctOptionIndex: 1),
        QuizQuestion(text: "Which country hosted the 1974 World Cup?", options: ["West Germany", "East Germany", "Netherlands"], correctOptionIndex: 0),
        QuizQuestion(text: "Who was the coach of France in 1998?", options: ["Jacquet", "Lemerre", "Platini"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country won the 1962 World Cup?", options: ["Brazil", "Czech Republic", "Chile"], correctOptionIndex: 0),
        
        QuizQuestion(text: "Who scored the winning penalty in 2006?", options: ["Grosso", "Del Piero", "Pirlo"], correctOptionIndex: 0),
        QuizQuestion(text: "Which team finished 2nd in 2002?", options: ["Turkey", "Germany", "South Korea"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the top scorer in 1990?", options: ["Schillaci", "Matthaus", "Klinsmann"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 1938 World Cup?", options: ["Italy", "France", "Switzerland"], correctOptionIndex: 1),
        QuizQuestion(text: "Who won the Golden Glove in 2006?", options: ["Buffon", "Barthez", "Lehmann"], correctOptionIndex: 0),
        
        // Final batch to get to 100
        QuizQuestion(text: "Which team did West Germany beat in 1990 final?", options: ["Argentina", "England", "Cameraoon"], correctOptionIndex: 0),
        QuizQuestion(text: "Who was the captain of West Germany in 1990?", options: ["Matthaus", "Brehme", "Klinsmann"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country won the 1970 World Cup?", options: ["Italy", "Brazil", "West Germany"], correctOptionIndex: 1),
        QuizQuestion(text: "Who was the top scorer in 1970?", options: ["Muller", "Jairzinho", "Pele"], correctOptionIndex: 0),
        QuizQuestion(text: "Which country hosted the 2018 World Cup?", options: ["Russia", "Qatar", "Brazil"], correctOptionIndex: 0)
    ]
}
