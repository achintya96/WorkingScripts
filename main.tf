#Main TF Script to create Cloud Resources on AWS


#  Define data sources

data "mso_site" "aws_site" {
  name = var.aws_site_name
}
data "mso_user" "user1" {
  username = var.username             #uses your user name variable
}


#######################

#Here is where you will be creating the tenant resource mso_tenant 'tenant'

# Create a tenant resource (resource "mso_tenant" "tenant") and pass the arguments nessesary
# note: please use the same va
# Sneek Peek at our main repo https://github.com/achintya96/LTRDCN-2691 if you are stuck with the creation of the tenant

########################


# You do not need to modify the folowing code. As you can see, we are referencing the resource mso_tenant.tenant that you would create above

## create schema

resource "mso_schema" "schema1" {
  name          = var.schema_name
  template_name = var.template_name
  tenant_id     = mso_tenant.tenant.id
  depends_on = [
  mso_tenant.tenant
  ]
}




## Associate Schema / template with Site

resource "mso_schema_site" "aws_site" {
  schema_id     = mso_schema.schema1.id
  site_id       = data.mso_site.aws_site.id
  template_name = mso_schema.schema1.template_name
  depends_on = [
  mso_tenant.tenant,
  mso_schema.schema1
  ]
}




## Create VRF and associate with template

resource "mso_schema_template_vrf" "vrf1" {
  schema_id        = mso_schema.schema1.id
  template         = mso_schema.schema1.template_name
  name             = var.vrf_name
  display_name     = var.vrf_name
  layer3_multicast = false
  vzany            = false
}

#######

# Associate VRF with Schema

resource "mso_schema_site_vrf" "aws_site" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema_site.aws_site.template_name
  site_id       = data.mso_site.aws_site.id
  vrf_name      = mso_schema_template_vrf.vrf1.name
}



## associate with Region and zones in Site Local Templates
resource "mso_schema_site_vrf_region" "vrfRegion" {
  schema_id          = mso_schema.schema1.id
  template_name      = mso_schema_site.aws_site.template_name
  site_id            = data.mso_site.aws_site.id
  vrf_name           = mso_schema_site_vrf.aws_site.vrf_name
  region_name        = var.region_name
  vpn_gateway        = true    # required for commmunication between cloud and onprem
  hub_network_enable = false
  cidr {
    cidr_ip = var.cidr_ip
    primary = true

    subnet {
      ip    = var.subnet1
      zone  = var.zone1
      usage = "gateway"
    }

    subnet {
      ip    = var.subnet2
      zone  = var.zone2
      #usage = "not used "
    }

    subnet {
      ip   = var.subnet3
      zone = var.zone3
      #usage = "not_used_since_each_zone_can_have_1__gateway"
    }

  }

}

## create ANP

resource "mso_schema_template_anp" "anp1" {
  schema_id    = mso_schema.schema1.id
  template     = var.template_name
  name         = var.anp_name
  display_name = var.anp_name
  depends_on = [
     mso_tenant.tenant,
  mso_schema.schema1,
  mso_schema_site.aws_site,
  mso_schema_template_vrf.vrf1,
  mso_schema_site_vrf.aws_site,
  mso_schema_site_vrf_region.vrfRegion
  ]
}


resource "mso_schema_site_anp" "anp1" {
  schema_id     = mso_schema.schema1.id
  anp_name      = mso_schema_template_anp.anp1.name
  template_name = var.template_name
  site_id       = data.mso_site.aws_site.id
/*  depends_on = [
  mso_tenant.tenant,
  mso_schema.schema1,
  mso_schema_site.aws_site,
  mso_schema_template_vrf.vrf1,
  mso_schema_site_vrf.aws_site,
  mso_schema_site_vrf_region.vrfRegion,
  mso_schema_template_anp.anp1
  ]*/
}



### Deploy Template:
resource "mso_schema_template_deploy" "template_deployer" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema.schema1.template_name
  depends_on = [
    mso_tenant.tenant,
    mso_schema.schema1,
    mso_schema_site.aws_site,
    mso_schema_template_vrf.vrf1,
    mso_schema_site_vrf.aws_site,
    mso_schema_site_vrf_region.vrfRegion,
    mso_schema_template_anp.anp1,
  ]
  #undeploy = true
}
