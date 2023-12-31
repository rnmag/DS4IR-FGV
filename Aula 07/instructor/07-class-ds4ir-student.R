# ---
#   title: "DS4IR"
# subtitle: "An�lise multivariada e modelos preditivos"
# author: 
#   - Professor Davi Moreira
# - Professor Rafael Magalh�es
# date: "`r format(Sys.time(), '%d-%m-%Y')`"
# output: 
#   revealjs::revealjs_presentation:
#   theme: simple
# highlight: haddock
# transition: slide
# center: true
# css: stylesheet.css
# reveal_options:
#   controls: false  # Desativar bot�es de navega��o no slide
# mouseWheel: true # Passar slides com o mouse
# ---
#   
#   ## Programa
#   
#   - Tend�ncias e res�duos
# - Modelos preditivos
# - M�ltiplos modelos
# - Pontos ideais
# 
# ## Motiva��o
# Qual foi o padr�o de desenvolvimento dos pa�ses no s�culo XX? Como conseguimos identificar a tend�ncia principal dessa evolu��o. Talvez mais importante, como identificar os casos que n�o seguem a tend�ncia geral?
#   
#   A decomposi��o de res�duos e tend�ncias pode nos ajudar a responder essas perguntas, e as ferramentas de programa��o funcional nos permitir�o faz�-lo em bases de dados mais complexas do que as que vimos at� agora.
# 
# 
# ## An�lise de modelos
# Na aula passada, vimos o funcionamento de modelos lineares. Hoje vamos explor�-los um pouco mais, mostrando como podemos separ�-los analiticamente em **tend�ncias** e **res�duos**
#   
#   A ideia � evitar usar modelos como caixas pretas, que produzem resultados que n�o entendemos. Por meio de um modelo quantitativo que inclui informa��es dispon�veis nos dados e na sua experi�ncia, podemos abstrair conclus�es que podem ser aplicadas em novos contextos.
# 
# ## Primeiros passos
# Vamos introduzir o tema com um modelo simples de um banco de dados j� conhecido, a fim de responder � seguinte pergunta: por que diamantes de pior qualidade s�o os mais caros?
#   
#   Prosseguiremos com um banco de dados did�ticos para identificar padr�es de aloca��o de voos internacionais. Com as ferramentas que aprendermos nesses dois exemplos, seremos capazes de montar modelos mais complexos para identificar padr�es de desenvolvimento internacional.
# 
# ## Carregando as bases
# ```{r echo=TRUE, message=FALSE, warning=FALSE, results='hide'}
library(tidyverse)
library(modelr)
library(gapminder)
library(unvotes)
library(nycflights13) # banco de dados
library(lubridate) # processamento de datas
library(hexbin) # gr�ficos hexagonais
library(here)
# ``` 
# 
# ## Qualidade vs pre�o
# ```{r fig.align='center'}
diamonds %>% ggplot(aes(cut, price)) + geom_boxplot()
# ```
# 
# ## Qualidade vs pre�o
# ```{r fig.align='center'}
diamonds %>% ggplot(aes(color, price)) + geom_boxplot()
# ```
# 
# ## Qualidade vs pre�o
# ```{r fig.align='center'}
diamonds %>% ggplot(aes(clarity, price)) + geom_boxplot()
# ```
# 
# ## Determinantes do pre�o
# Diamantes om pior corte, clareza e pureza parecem ter pre�os similares aos dos seus pares por causa de uma vari�vel omitida: o peso.
# 
# ```{r echo=FALSE, fig.align='center'}
ggplot(diamonds, aes(carat, price)) + 
  geom_hex(bins = 50)
# ```
# 
# ## Determinantes do pre�o
# A rela��o fica ainda mais clara quando fazemos uma transforma��o logaritmica nas vari�veis
# 
# ```{r echo=FALSE, fig.align='center'}
diamonds2 <- diamonds %>% 
  filter(carat <= 2.5) %>% 
  mutate(lprice = log2(price), lcarat = log2(carat))

ggplot(diamonds2, aes(lcarat, lprice)) + 
  geom_hex(bins = 50)
# ```
# 
# ## Elimina��o do sinal
# Agora que observamos uma rela��o linear entre peso e pre�o, podemos come�ar a trabalhar na nossa decomposi��o entre elementos de tend�ncia e de res�duo. 
# 
# ```{r echo=FALSE, fig.align='center'}
mod_diamond <- lm(lprice ~ lcarat, data = diamonds2)

grid <- diamonds2 %>% 
  data_grid(carat = seq_range(carat, 20)) %>% 
  mutate(lcarat = log2(carat)) %>% 
  add_predictions(mod_diamond, "lprice") %>% 
  mutate(price = 2 ^ lprice)

ggplot(diamonds2, aes(carat, price)) + 
  geom_hex(bins = 50) + 
  geom_line(data = grid, colour = "red", size = 1)
# ```
# 
# 
# ## An�lise de res�duos
# Uma vez que tiramos o componente linear dessa rela��o, os res�duos devem mostrar pouca associa��o entre peso e pre�o
# 
# ```{r echo=FALSE, fig.align='center'}
diamonds2 <- diamonds2 %>% 
  add_residuals(mod_diamond, "lresid")

ggplot(diamonds2, aes(lcarat, lresid)) + 
  geom_hex(bins = 50)
# ```
# 
# ## Retorno: qualidade vs pre�o
# ```{r fig.align='center'}
diamonds2 %>% ggplot(aes(cut, lresid)) + geom_boxplot()
# ```
# 
# ## Retorno: qualidade vs pre�o
# ```{r fig.align='center'}
diamonds2 %>% ggplot(aes(color, lresid)) + geom_boxplot()
# ```
# 
# ## Retorno: qualidade vs pre�o
# ```{r fig.align='center'}
diamonds2 %>% ggplot(aes(clarity, lresid)) + geom_boxplot()
# ```
# 
# ## Adicionando mais vari�veis
# O que vimos no exemplo anterior foi o processo de "controle" da vari�vel `peso`, a fim de observar uma associa��o mais limpa entre a qualidade dos diamantes e seu pre�o. Como vimos ontem, podemos controlar por todas as vari�veis ao mesmo tempo por meio da regress�o.
# 
# ```{r}
mod_diamond2 <- lm(lprice ~ lcarat + color + cut + clarity, data = diamonds2)

grid <- diamonds2 %>% 
  data_grid(cut, .model = mod_diamond2) %>% 
  add_predictions(mod_diamond2)
# ```
# 
# ## Adicionando mais vari�veis
# ```{r fig.align='center'}
ggplot(grid, aes(cut, pred)) + geom_point()
# ```
# 
# ## An�lise dos res�duos
# Aparentemente, mesmo controlando por peso e quantidade, ainda h� diamantes com pre�o maior do que o esperado!
#   
#   ```{r echo=FALSE, fig.align='center'}
diamonds2 <- diamonds2 %>% 
  add_residuals(mod_diamond2, "lresid2")

ggplot(diamonds2, aes(lcarat, lresid2)) + 
  geom_hex(bins = 50)
# ```
# 
# 
# ## Exerc�cio
# Quais s�o os diamantes com maiores e menores res�duos de acordo com o modelo multivariado?
#   
#   ## Exerc�cio: resposta
#   <!--- 
#   diamonds2 %>% arrange(lresid2)
# diamonds2 %>% arrange(desc(lresid2))
# --->
#   
#   ## Padr�es de voos em Nova York
#   
#   Esta base de dados vai nos ajudar a enxergar a riqueza das ferramentas de previs�o e identifica��o de tend�ncias. Vamos partir de uma base rica sobre voos nos Estados Unidos, e transform�-la em um banco com apenas 365 linhas e 2 colunas, registrando o n�mero de v�os que saem de Nova York todos os dias.
# 
# ```{r echo=TRUE, results='hide'}
flights
# ```
# 
# 
# ## Transforma��o dos dados
# ```{r echo=TRUE, results='hide'}
daily <- flights %>% 
  mutate(date = make_date(year, month, day)) %>% 
  group_by(date) %>% 
  summarise(n = n())
# ```
# 
# ## Inspe��o visual
# H� um padr�o claro nessa an�lise explorat�ria. Quais s�o os dias com queda t�o forte de voos?
#   
#   ```{r echo=FALSE, fig.align='center'}
ggplot(daily, aes(date, n)) + geom_line()
# ```
# 
# ## Voos por dia da semana
# ```{r echo=TRUE, fig.align='center'}
daily <- daily %>% mutate(wday = wday(date, label = TRUE))
ggplot(daily, aes(wday, n)) + geom_boxplot()
# ```
# 
# ## Identifica��o da tend�ncia
# H� um padr�o claro de menos voos nos fins de semana. Vamos modelar?
#   ```{r echo=FALSE, fig.align='center'}
mod <- lm(n ~ wday, data = daily)

grid <- daily %>% 
  data_grid(wday) %>% 
  add_predictions(mod, "n")

ggplot(daily, aes(wday, n)) + 
  geom_boxplot() +
  geom_point(data = grid, colour = "red", size = 4)
# ```
# 
# ## Visualiza��o dos res�duos
# ```{r echo=FALSE, fig.align='center'}
daily <- daily %>% 
  add_residuals(mod)

daily %>% ggplot(aes(date, resid)) + 
  geom_ref_line(h = 0) + 
  geom_line()
# ```
# 
# ## An�lise dos res�duos
# O que podemos ver nos res�duos?
#   
#   1. O modelo n�o est� modelando bem o per�odo de junho, com res�duos regularmente mais altos.
# 
# ```{r echo=FALSE, fig.align='center'}
ggplot(daily, aes(date, resid, colour = wday)) + 
  geom_ref_line(h = 0) + 
  geom_line()
# ```
# 
# ## An�lise dos res�duos
# 2. H� alguns dias com bem menos voos do que o esperado
# 
# ```{r echo=TRUE}
daily %>% filter(resid < -100)
# ```
# 
# ## An�lise dos res�duos
# 3. Existe uma tend�ncia de menos voos nos meses de inverno, pareada com maior frequ�ncia nos meses de ver�o
# 
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
daily %>% 
  ggplot(aes(date, resid)) + 
  geom_ref_line(h = 0) + 
  geom_line(colour = "grey50") + 
  geom_smooth(se = FALSE, span = 0.20)
# ```
# 
# 
# ## Centrando aten��o nos s�bados
# ```{r echo=FALSE, fig.align='center'}
daily %>% 
  filter(wday == "s�b") %>% 
  ggplot(aes(date, n)) + 
  geom_point() + 
  geom_line() +
  scale_x_date(NULL, date_breaks = "1 month", date_labels = "%b")
# ```
# 
# ## Centrando aten��o nos s�bados
# Existe uma alta clara no ver�o, mas o que acontece nos demais per�odos? Vamos examinar:
#   
#   ```{r echo=FALSE, fig.align='center'}
term <- function(date) {
  cut(date, 
      breaks = ymd(20130101, 20130605, 20130825, 20140101),
      labels = c("spring", "summer", "fall") 
  )
}

daily <- daily %>% 
  mutate(term = term(date)) 

daily %>% 
  filter(wday == "s�b") %>% 
  ggplot(aes(date, n, colour = term)) +
  geom_point(alpha = 1/3) + 
  geom_line() +
  scale_x_date(NULL, date_breaks = "1 month", date_labels = "%b")
# ```
# 
# ## Esse padr�o se repete nos outros dias?
# 
# ```{r echo=FALSE, fig.align='center'}
daily %>% 
  ggplot(aes(wday, n, colour = term)) +
  geom_boxplot()
# ```
# 
# ## An�lise da intera��o
# ```{r echo=FALSE, fig.align='center'}
mod1 <- lm(n ~ wday, data = daily)
mod2 <- lm(n ~ wday * term, data = daily)

daily %>% 
  gather_residuals(without_term = mod1, with_term = mod2) %>% 
  ggplot(aes(date, resid, colour = model)) +
  geom_line(alpha = 0.75)
# ```
# 
# ## An�lise da intera��o
# Podemos observar que os outliers n�o deixam a intera��o melhorar o modelo
# ```{r echo=FALSE, fig.align='center'}
grid <- daily %>% 
  data_grid(wday, term) %>% 
  add_predictions(mod2, "n")

ggplot(daily, aes(wday, n)) +
  geom_boxplot() + 
  geom_point(data = grid, colour = "red") + 
  facet_wrap(~ term)
# ```
# 
# ## Modelo robusto
# Um modelo robusto melhora bastante nossa previs�o
# 
# ```{r echo=FALSE, fig.align='center'}
mod3 <- MASS::rlm(n ~ wday * term, data = daily)

daily %>% 
  add_residuals(mod3, "resid") %>% 
  ggplot(aes(date, resid)) + 
  geom_hline(yintercept = 0, size = 2, colour = "white") + 
  geom_line()
# ```
# 
# 
# ## Ajustando mais de um modelo
# 
# ## Agora � pra valer!
# Agora que temos as t�cnicas b�sicas, podemos fazer um exerc�cio mais ambicioso. Vamos rodar v�rios modelos para entender um banco de dados mais complexo, com fen�menos parecidos com aqueles que costumamos estudar.
# 
# Isso vai exigir que a gente armazene resultados em estruturas mais sofisticadas. Assim, vamos conseguir separar tend�ncias mais fortes nos dados para revelar padr�es mais sutis, que talvez n�o pud�ssemos capturar � primeira vista.
# 
# Vamos responder � seguinte pergunta: como a expectativa de vida evoluiu nos �ltimos anos em cada pa�s?
#   
#   ```{r echo=TRUE, results='hide'}
gapminder
# ```
# 
# ## Evolu��o por pa�s
# Voc� v� uma tend�ncia?
#   
#   ```{r echo=FALSE, fig.align='center'}
gapminder %>% 
  ggplot(aes(year, lifeExp, group = country)) +
  geom_line(alpha = 1/3)
# ```
# 
# ## An�lise de um pa�s
# ```{r echo=FALSE, fig.align='center'}
nz <- filter(gapminder, country == "New Zealand")
nz %>% 
  ggplot(aes(year, lifeExp)) + 
  geom_line() + 
  ggtitle("Full data - New Zealand")
# ```
# 
# ## An�lise de um pa�s
# ```{r echo=FALSE, fig.align='center'}
nz_mod <- lm(lifeExp ~ year, data = nz)
nz %>% 
  add_predictions(nz_mod) %>%
  ggplot(aes(year, pred)) + 
  geom_line() + 
  ggtitle("Linear trend - New Zealand")
# ```
# 
# ## An�lise de um pa�s
# ```{r echo=FALSE, fig.align='center'}
nz %>% 
  add_residuals(nz_mod) %>% 
  ggplot(aes(year, resid)) + 
  geom_hline(yintercept = 0, colour = "white", size = 3) + 
  geom_line() + 
  ggtitle("Remaining pattern - New Zealand")
# ```
# 
# ## Mas e os demais?
# J� vimos como decompor o res�duo quando temos apenas um caso. Mas como podemos identificar os pa�ses que n�o seguem a tend�ncia geral que observamos? Temos que rodar um a um?
#   
#   O princ�pio da pregui�a nos d� a resposta: **n�o**.
# 
# ## Dados aninhados
# Queremos repetir a mesma opera��o para diferentes observa��es na nossa base de dados (ou seja, decompor tend�ncia e res�duo por pa�s). 
# 
# Vamos usar uma estrutura de dados que tem apenas uma linha para cada pa�s, e uma coluna especial chamada `data`. Esta coluna � uma lista de dataframes (dentro do nosso dataframe!)
# 
# ```{r echo=TRUE, results='hide'}
by_country <- gapminder %>% 
  group_by(country, continent) %>% 
  nest()
# ```
# 
# ## Dados aninhados
# Se olharmos para o valor de apenas uma dessas listas, vemos que ela contem todas as informa��s, **por ano**, daquele pa�s.
# 
# ```{r echo=TRUE, results='hide'}
by_country$data[[1]]
# ```
# 
# Portanto, agora temos uma base de dados em que cada linha n�o � s� uma observa��o; � um conjunto delas!
#   
#   ## Adicionando mais uma lista
#   Para poder rodar nosso modelo em cada conjunto de observa��es, vamos criar uma nova fun��o:
#   
#   ```{r echo=TRUE, results='hide'}
country_model <- function(df) {
  lm(lifeExp ~ year, data = df)
}
# ```
# 
# Agora, podemos usar a fun��o `purrr::map` para aplicar nosso modelo a cada conjunto de observa��es. *And just like that*, temos uma segunda lista de data frames dentro do nosso data frame
# 
# ```{r echo=TRUE, results='hide'}
by_country <- by_country %>% 
  mutate(model = map(data, country_model))
# ```
# 
# ## Hora de sair do ninho
# Neste ponto, n�s temos 142 modelos na nossa base. Para fazer a an�lise de res�duos em todos eles, seguimos a mesma l�gica:
#   
#   ```{r echo=TRUE, results='hide'}
by_country <- by_country %>% 
  mutate(resids = map2(data, model, add_residuals))
# ```
# 
# Agora que j� temos todos os c�lculos que quer�amos, podemos desaninhar os modelos para poder coloc�-los em gr�ficos
# 
# ```{r echo=TRUE, results='hide'}
resids <- unnest(by_country, resids)
# ```
# 
# ## Res�duos de todos os pa�ses
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
resids %>% 
  ggplot(aes(year, resid)) +
  geom_line(aes(group = country), alpha = 1 / 3) + 
  geom_smooth(se = FALSE)
# ```
# 
# ## Separando por continente
# 
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
resids %>% 
  ggplot(aes(year, resid, group = country)) +
  geom_line(alpha = 1 / 3) + 
  facet_wrap(~continent)
# ```
# 
# ## Identificando os piores ajustes
# ```{r echo=TRUE}
glance <- by_country %>% 
  mutate(glance = map(model, broom::glance)) %>% 
  unnest(glance) %>% 
  arrange(r.squared)

glance
# ```
# 
# ## Um olhar para a �frica
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
glance %>% 
  ggplot(aes(continent, r.squared)) + 
  geom_jitter(width = 0.5)
# ```
# 
# ## Um olhar para a �frica
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
bad_fit <- filter(glance, r.squared < 0.25)

gapminder %>% 
  semi_join(bad_fit, by = "country") %>% 
  ggplot(aes(year, lifeExp, colour = country)) +
  geom_line()
# ```
# 
# 
# ## Vota��es na AGNU
# Para ilustrar o poder das t�cnicas de redu��o de dimensionalidade, vamos explorar a base de dados de vota��es nominais da Assembleia Geral das Na��es Unidas desde 1946.
# 
# ```{r echo=TRUE, results='hide'}
# Vota��o de cada pa�s
un_votes 

# Informa��es sobre cada vota��o
un_roll_calls

# Tema das vota��es
un_roll_call_issues
# ```
# 
# ## Temas mais comuns
# ```{r echo=TRUE}
un_roll_call_issues %>% count(issue, sort = TRUE)
# ```
# 
# ## Tend�ncia de "Sim" para pa�ses selecionados
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
joined <- un_votes %>%
  inner_join(un_roll_calls, by = "rcid")

by_country_year <- joined %>%
  group_by(year = year(date), country) %>%
  summarize(votes = n(),
            percent_yes = mean(vote == "yes"))

countries <- c('Brazil', 'United States of America', 'Argentina')

by_country_year %>% 
  filter(country %in% countries) %>%
  ggplot(aes(x = year, y = percent_yes, color = country)) + 
  geom_line() +
  ylab("% of votes are 'Yes'") + 
  ggtitle("Trend in percentage Yes Votes 1946-2015") + 
  theme_minimal()
# ```
# 
# ## Tend�ncia de vota��es do Brasil por tema
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
joined %>%
  filter(country == "Brazil") %>%
  inner_join(un_roll_call_issues, by = "rcid") %>%
  group_by(year = year(date), issue) %>%
  summarize(votes = n(),
            percent_yes = mean(vote == "yes")) %>%
  filter(votes > 5) %>%
  ggplot(aes(year, percent_yes)) +
  geom_point() +
  geom_smooth(se = FALSE) +
  facet_wrap(~ issue)
# ```
# 
# ## Ponto ideal do Brasil na UNGA
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
load(here("./data/UNVotes.RData"))

unga %>% ggplot(aes(year, IdealPoint.x)) +
  geom_line() + 
  theme_classic()

# ```
# 
# ## Dist�ncia do Brasil em rela��o a Argentina
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
unga %>% 
  filter(ccode2 == 160) %>% 
  ggplot(aes(year, IdealPointDistance)) +
  geom_line() + 
  theme_classic()

# ```
# 
# ## Dist�ncia do Brasil em rela��o aos EUA
# ```{r echo=FALSE, fig.align='center', message=FALSE, warning=FALSE}
unga %>% 
  filter(ccode2 == 2) %>% 
  ggplot(aes(year, IdealPointDistance)) +
  geom_line() + 
  theme_classic()
# 
# ```
# 
# 
# 
# ## Material adicional
# 
# - [Dataverse - Eric Voeten](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/LEJUQZ)
# - [Statistical Modeling: A Fresh Approach by Danny Kaplan](http://project-mosaic-books.com/?page_id=13)
# - [Applied Predictive Modeling](http://appliedpredictivemodeling.com)
# 
# 
# ## Tarefa da aula
# 
# As instru��es da tarefa est�o no arquivo `NN-class-ds4ir-assignment.rmd` da pasta 
# `assignment` que se encontra na raiz desse projeto.
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
