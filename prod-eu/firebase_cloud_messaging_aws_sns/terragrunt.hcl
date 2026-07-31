include "root" {
  path = find_in_parent_folders()
}

locals {
  module_name = basename(get_terragrunt_dir())
  aws_profile = get_env("AWS_PROFILE")
  bucket_name = "bfan-terraform-state-bucket-${split("-", local.aws_profile)[0]}"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    profile = "${local.aws_profile}"
    bucket  = "${local.bucket_name}"
    key     = "${local.module_name}.tfstate"
    region  = "eu-west-1"
    # dynamodb_table = "terraform-state-lock" # TODO: Create a DynamoDB table for state locking
  }
}
EOF
}

terraform {
  source = "${get_parent_terragrunt_dir()}//modules/${local.module_name}"
}

inputs = {
  aws_env_name = local.aws_profile
  org_id_to_project_id = {
    acajaccio              = "bfan-acajaccio"
    asmonaco               = "bfan-asmonaco"
    avironbayonnais        = "bfan-avironbayonnais"
    asbh                   = "bfan-asbhrugby"
    asse                   = "sixth-trainer-109314"
    asvel                  = "bfan-asvel"
    berlinrecyclingvolley  = "berlinrecyclingvolley"
    besiktas               = "bfansports"
    bfanteam               = "bfanteam"
    billerehandball        = "bfan-billerehandball"
    boxers                 = "bfan-boxers"
    briverugby             = "bfan-briverugby"
    bruleursdeloups        = "bfan-bruleursdeloups"
    catalansdragons        = "bfan-catalansdragons"
    castresolympique       = "bfan-castresolympique"
    clermontfoot63         = "bfan-clermontfoot63"
    corsairesdenantes      = "bfan-corsairesdenantes"
    dragonsderouen         = "bfan-dragonsderouen"
    dresdnerscvolley       = "bfan-dresdnerscvolley"
    elanchalon             = "bfan-elanchalon"
    fclorient              = "bfan-fclorient"
    fcnantes               = "bfan-fcnantes"
    fclausannesport        = "fclausannesport-b65e6"
    ffrugby                = "ffrugby-895ee"
    fkcrvenazvezda         = "fk-crvena-zvezda"
    francegalop            = "bfan-francegalop"
    fribourggotteronhc     = "bfan-fribourggotteronhc"
    geneveservettehc       = "bfan-geneveservettehc"
    girondins              = "bfan-girondins"
    gothiques              = "bfan-gothiques" 
    gpfrance               = "bfan-gpfrance"
    grenoblefoot38           = "bfan-grenoblefoot38"
    jdadijonbasket         = "bfansports"
    jlbourg                = "bfan-jlbourg"
    lausannehockeyclub     = "bfansports"
    levalloismetropolitans = "bfan-levalloismetropolitans"
    losc                   = "bfan-losc"
    lourugby               = "bfan-lourugby"
    mhsc                   = "bfan-mhsc" 
    montecarlotennismasters = "bfansports"
    montpellierheraultrugby = "bfan-montpellierheraultrugby"
    nanterre92             = "bfan-nanterre92"
    ogcnice                = "bfan-ogcnice"
    olympiquelyonnais      = "olvallee-appmobile-prod"
    olympiquedemarseille   = "global-wharf-825"
    orleansfc              = "bfan-orlansfc"
    oyonnaxrugby           = "bfan-oyonnaxrugby"
    parisfc                = "bfan-parisfc"
    palermofc              = "bfan-palermofc"
    parisbasketball        = "parisbasketball-fab9d"
    parissaintgermain      = "bfan-parissaintgermain"
    pionnierschamonixbiz   = "bfan-pionnierschamonixbiz"
    psgstadium             = "bfan-parissaintgermain"
    quevillyrouenmetropole = "bfan-quevillyrouenmetropole"
    rcstrasbourgalsace     = "rcstrasbourgalsace-rcsa"
    rctoulon               = "bfan-rctoulon"
    rodezaveyronfootball   = "bfan-rodezaveyronfootball"
    rouennormandierugby    = "bfan-rouennormandierugby"
    royalcharleroisportingclub = "bfan-royalcharleroisportingclu"
    saxvcharenterugby      = "bfan-saxvcharenterugby"
    sccschwerinvolley     = "bfan-sccschwerinvolley"
    scpotsdam              = "bfan-scpotsdam"
    scuemlichheimvolley    = "bfan-scuemlichheimvolley"
    sectionpaloise         = "bfan-sectionpaloise"
    servettefc             = "bfan-servettefc"
    svgluneburg            = "bfan-svgluneburg"
    smcaen                 = "bfan-smcaen"
    stadebrestois          = "bfansports"
    stadefrancais          = "bfan-stadefrancais"
    staderochelais         = "bfansports"
    stadetoulousain        = "bfan-stadetoulousain"
    toulousefc             = "bfan-toulousefc"
    toursvolleyball        = "bfan-toursvolleyball"
    turktelekom            = "bfansports"
    ubbrugby               = "bfan-ubbrugby"
    uscarcassonne          = "uscarcassonne-prod"
    usap                   = "bfan-usap"
    valenceromansdromerugby = "bfan-valenceromansdromerugby"
    vcwiesbaden            = "bfan-vcwiesbaden"
  }
  excluded_project_ids = []
}
