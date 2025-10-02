
########################

#Conduct OLS to confirm interaction effects as reported in section 3.3. Interaction of mediator variables

#######################

###
#Interaction median age, uhc 
###

df_complete_all %>%
  {lm(scale(excess_mort) ~ scale(median_age) + scale(uhc) + (scale(median_age)*scale(uhc)), .)} %>%   
  summary()

# interaction between median age and uhc is significant on 1% level
# beta of median_age*uhc = -15.426. 
# for each one-unit increase in uhc, the effect (slope) of median age on mortality decreases by 15 units.
# In other words, the relationship between median age and mortality becomes weaker as uhc increases,
# and the effect of uhc becomes more negative (higher negative impact) as age increases.

###
#Interaction median age, vacc
###

df_complete_all %>%
  {lm(scale(excess_mort) ~ scale(median_age) + scale(vacc) + (scale(median_age)*scale(vacc)), .)} %>%   
  summary()


###
#Interaction age 65 and above, uhc
###

df_complete_all %>%
  {lm(scale(excess_mort) ~ scale(age_65plus) + scale(uhc) + (scale(age_65plus)*scale(uhc)), .)} %>%   
  summary()


###
#Interaction age 65 and above, vacc
###

df_complete_all %>%
  {lm(scale(excess_mort) ~ scale(age_65plus) + scale(vacc) + (scale(age_65plus)*scale(vacc)), .)} %>%   
  summary()