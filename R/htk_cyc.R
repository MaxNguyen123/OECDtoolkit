#'@title compare-your-country plot for each selected indicator in the housing toolkit chapters
#'
#'@description The functions generates a (line) plot displaying the value of the selected indicator for each country and with the average OECD value, the bottom and top performing countries.
#'@param mydata dataframe that contains the variables and dates to be chosen
#'@param ctry selected OECD countries for which the country note is produced
#'@param var_codes list of indicators
#'@param var_names names of the indicators
#'@param sec_col colours for each section
#'@param title a title for the figure
#'
#'@return returns a standardized plot
#'
#'@author
#'Manuel Betin
#'Federica De Pace
#'
#'@export



htk_CyC=function(mydata,ctry,var_codes,var_names,sec_col, title=NULL){

  country_name=countrycode(ctry,origin = "iso3c",destination="country.name")

  vars_needed<- mydata %>%  select(country, var_codes) %>%
    mutate_at(vars(var_codes),.funs=list(mean=~mean(.,na.rm=T),
                                         min=~min(.,na.rm=T),
                                         max=~max(.,na.rm=T)))
  # 2. create min, max, mean, valu
  for (var in var_codes) {
    name_col=paste0(var, '_country_min')
    vars_needed<- vars_needed %>%
      mutate(!!name_col := vars_needed$country[which.min(get(var))] )
  }

  for (var in var_codes) {
    name_col=paste0(var, '_country_max')
    vars_needed<- vars_needed %>%
      mutate(!!name_col := vars_needed$country[which.max(get(var))] )
  }

  temp_long<- vars_needed %>%  filter(country==ctry)%>% dplyr::select(-country) %>%
    gather(key = "variable", value = "value")

   for (var in var_codes) {
      temp_long<-temp_long %>%
        mutate(main_v=ifelse( (str_detect(variable, var_codes)), var_codes, NA))
   }
  temp_long<-temp_long %>%
    mutate(ext=ifelse( (str_detect(variable, "mean")), "mean", "value"),
           ext=ifelse( (str_detect(variable, "min")), "min", ext),
           ext=ifelse( (str_detect(variable, "max")), "max", ext),
           ext=ifelse( (str_detect(variable, "country_max")), "country_max", ext),
           ext=ifelse( (str_detect(variable, "country_min")), "country_min", ext)) %>%
    dplyr::select(-variable)

  final<-reshape(temp_long, idvar = "main_v" , timevar =  "ext" , direction = "wide")

  name_vars<-c("value.value","value.mean","value.min","value.max")
  final<-  final %>% mutate_at(vars(name_vars),as.numeric) %>%
    mutate(value_scaled = (value.value-value.min) / (value.max-value.min ),
           mean_scaled =  ( value.mean-value.min) / (value.max-value.min ) )

  ggplot(data=final,aes(x=main_v))+
    geom_segment(aes(xend=main_v, y=0, yend=1), color="grey") +
    geom_point(aes(y= value_scaled ), shape=19, color='red', size=4)  +
    geom_point(aes(y=mean_scaled  ) , shape=18, color='darkblue', size=3) +
    geom_point(aes(y=0), shape=1, color='grey', size=2)  +
    geom_point(aes(y=1 ), shape=1, color='grey', size=2) +
    coord_flip() +
    labs(x = "", y="",
         title=title) +
    theme(panel.background = element_blank(),
          axis.text.x = element_blank(),
          plot.title=element_text(face="bold",colour ="black",size=15, hjust =0.5),
          axis.text.y = element_text(angle=60,size=13,color=sec_col),
          axis.ticks =element_blank() )+
    scale_x_discrete(breaks=final$main_v,labels=var_names) +
    geom_text(aes(y= value_scaled   , label=paste(country_name,": ", round(value.value, digits = 2))),
              size=5, nudge_x = -0.1, nudge_y = 0.0,  check_overlap = TRUE) +
    geom_text(aes(y= mean_scaled   , label=paste("OECD: ", round(value.mean, digits = 2))),
              size=5, nudge_x = 0.1, nudge_y = 0.0,  check_overlap = TRUE,color="steelblue") +
    geom_text(aes(y= 0   , label=paste(value.country_min,":" , round(value.min, digits = 2))),
              size=5, nudge_x = 0.2, nudge_y = 0.03,  check_overlap = TRUE,color="steelblue") +
    geom_text(aes(y= 1   , label=paste(value.country_max,":", round(value.max, digits = 2))),
              size=5, nudge_x = 0.2, nudge_y = -0.05,  check_overlap = TRUE,color="steelblue")+
    annotate("text", x =3.4, y = 0.14, label = "Bottom OECD performer", size=5,color="darkgrey") +
    annotate("text", x =3.4, y = 0.90, label = "Top OECD performer", size=5,color="darkgrey")

}
