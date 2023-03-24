#!/bin/bash

source utils/functions
IPSEC_SECRET=/etc/ipsec.secrets

addVPNUser $IPSEC_SECRET
