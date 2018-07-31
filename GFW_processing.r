# ```{r}
# sql <- 'SELECT
#   a.year year,
#   a.mmsi mmsi,
#   b.best_label best_label,
#   b.best_flag best_flag,
#   b.best_length best_length,
#   b.best_tonnage best_tonnage,
#   b.best_engine_power best_engine_power,
#   FLOOR(a.lat*10)/10 + .05 lat_bin_center,
#   FLOOR(a.lon*10)/10 + .05 lon_bin_center,
#   SUM(a.hours) fishing_hours
# FROM (
#   SELECT
#     mmsi,
#     EXTRACT(YEAR FROM timestamp) AS year,
#     lat,
#     lon,
#     eez_iso3,
#     hours,
#     nnet_score2,
#     seg_id
#   FROM
#     `world-fishing-827.gfw_research.nn7`
#   WHERE
#     _PARTITIONTIME >= "2014-01-01 00:00:00"
#     AND _PARTITIONTIME < "2018-01-01 00:00:00"
#     AND seg_id IN (
#     SELECT
#       seg_id
#     FROM
#       `world-fishing-827.gfw_research.pipeline_p_p550_daily_segs`
#     WHERE
#       good_seg)) a
# INNER JOIN (
#   SELECT
#     year,
#     mmsi,
#     best_label,
#     best_flag,
#     best_length,
#     best_tonnage,
#     best_engine_power
#   FROM
#     `gfw_research.vessel_info_20180518`
#   WHERE
#     is_active
#     AND NOT offsetting
#     and best_flag = "USA"
#     and best_label = "trawlers") b
# ON
#   a.mmsi = b.mmsi
#   AND a.year = b.year
# WHERE
#   a.nnet_score2 = 1
#   AND a.lat >= 32.553
#   AND a.lat <= 41.9972
#   AND a.lon <= -115
#   AND a.lon >= -130
#   AND a.eez_iso3 = "USA"
# GROUP BY
#   year,
#   mmsi,
#   best_label,
#   best_flag,
#   best_length,
#   best_tonnage,
#   best_engine_power,
#   lat_bin_center,
#   lon_bin_center
# HAVING
#   fishing_hours > 0.01'
# 
# Cali_trawlers_effort <- dbGetQuery(BQ_connection, 
#                                 sql)

library(tidyverse)
library(mregions)
library(sf)
library(rmapshaper)
library(ggmap)
library(pals)


Cali_trawlers_effort <- read.csv("california-trawlers-effort.csv")

mr_names <- mregions::mr_names("MarineRegions:eez")

USA_eez <- mregions::mr_shp(key = "MarineRegions:eez",
                            filter = "United States Exclusive Economic Zone") %>% 
  sf::st_as_sf() %>% 
  rmapshaper::ms_simplify(keep = 0.003)

basemap <- ggmap::get_map(location = c("california"), maptype = "satellite", zoom = 5)

fishing_effort_map <- ggmap::ggmap(basemap) + 
  geom_sf(data = USA_eez, inherit.aes = FALSE, fill = "transparent", col = "darkred")+
  geom_raster(data = Cali_trawlers_effort %>% 
                group_by(lon_bin_center, lat_bin_center) %>% 
                summarize(fishing_hours = sum(fishing_hours)) %>% 
                ungroup() %>% 
                filter(fishing_hours > 1),
              aes(x = lon_bin_center, y = lat_bin_center, fill = fishing_hours))+
  scale_fill_gradientn(colours = pals::parula(100),
                       "fishing hours",
                       guide = "colourbar",
                       trans = "log",
                       breaks = scales::log_breaks(n = 10, base = 2))+
  labs(y = "", x = "", title = "Fishing effort")+
  theme(plot.title = element_text(color="black",hjust=0,vjust=1, size=rel(1)),
        plot.background = element_rect(fill="white"),
        panel.background = element_rect(fill="white"),
        legend.text = element_text(color = "black", size=rel(1)),
        legend.title = element_text(color = "black", size=rel(1)),
        legend.title.align = 1,
        legend.background = element_rect(fill="white"),
        legend.position = "right",
        legend.key.width = unit(0.5, "cm"),
        legend.margin = margin(l = 0, unit = 'cm'),
        legend.key.height = unit(.7, "cm"),
        legend.justification = "right",
        axis.text = element_text(color = "black", size=rel(1)))+
  guides(fill = guide_colourbar(title.position = "top", 
                                title.hjust = 0.5,
                                label.hjust = 0.5,
                                label.theme = element_text(angle = 0, size = 9)))+
  scale_x_continuous(expand = c(0,0),
                     limits = c(-130, -115))+
  scale_y_continuous(expand = c(0,0),
                     limits = c(32.553-1, 41.9972+1))


# https://rpubs.com/alobo/getmapCRS for possible crs correction stuff on a rainy day