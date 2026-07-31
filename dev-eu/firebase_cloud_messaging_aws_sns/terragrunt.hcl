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
    asbh                   = "bfan-asbhrugby"
    asse                   = "sixth-trainer-109314"
    asvel                  = "bfan-asvel"
    besiktas               = "bfansports"
    bfanteam               = "bfanteam"
    billerehandball        = "bfan-billerehandball"
    boxers                 = "bfan-boxers"
    briverugby             = "bfan-briverugby"
    catalansdragons        = "bfan-catalansdragons"
    castresolympique       = "bfan-castresolympique"
    corsairesdenantes      = "bfan-corsairesdenantes"
    dragonsderouen         = "bfan-dragonsderouen"
    elanchalon             = "bfan-elanchalon"
    fclorient              = "bfan-fclorient"
    fcnantes               = "bfan-fcnantes"
    fclausannesport        = "fclausannesport-b65e6"
    ffrugby                = "ffrugby-895ee"
    francegalop            = "bfan-francegalop"
    fribourggotteronhc     = "bfan-fribourggotteronhc"
    geneveservettehc       = "bfan-geneveservettehc"
    girondins              = "bfan-girondins"
    gpfrance               = "bfan-gpfrance"
    grenoblefoot           = "bfan-grenoblefoot38"
    jdadijonbasket         = "bfansports"
    jlbourg                = "bfan-jlbourg"
    lausannehockeyclub     = "bfansports"
    levalloismetropolitans = "bfan-levalloismetropolitans"
    losc                   = "bfan-losc"
    lourugby               = "bfan-lourugby"
    montecarlotennismasters = "bfansports"
    nanterre92             = "bfan-nanterre92"
    ogcnice                = "bfan-ogcnice"
    olympiquelyonnais      = "bfan-olympiquelyonnais"
    olympiquedemarseille   = "global-wharf-825"
    orleansfc              = "bfan-orlansfc"
    oyonnaxrugby           = "bfan-oyonnaxrugby"
    parisfc                = "bfan-parisfc"
    parissaintgermain      = "bfan-parissaintgermain"
    pionnierschamonix      = "bfan-pionnierschamonixbiz"
    psgstadium             = "bfan-parissaintgermain"
    rctoulon               = "bfan-rctoulon"
    sectionpaloise         = "bfan-sectionpaloise"
    servettefc             = "bfan-servettefc"
    smcaen                 = "bfan-smcaen"
    stadebrestois          = "bfansports"
    stadefrancais          = "bfan-stadefrancais"
    staderochelais         = "bfansports"
    stadetoulousain        = "bfan-stadetoulousain"
    toulousefc             = "bfan-toulousefc"
    turktelekom            = "bfansports"
    ubbrugby               = "bfan-ubbrugby"
    uscarcassonne          = "uscarcassonne-prod"
    usap                   = "bfan-usap"
  }
  excluded_project_ids = []
}
