CREATE OR REPLACE PACKAGE APPS.xxcso_009002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_009002j_pkg(SPEC)
 * Description      : �ڋq���Z�L�����e�B
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_party_upd_prdct         F  V     �p�[�e�B�iHZ_PARTIES�j�X�V���̒ǉ������擾
 *  get_org_pro_ext_ins_prdct   F  V     �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�쐬����
 *                                       �ǉ������擾
 *  get_org_pro_ext_upd_prdct   F  V     �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�X�V����
 *                                       �ǉ������擾
 *  get_org_pro_ext_del_prdct   F  V     �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�폜����
 *                                       �ǉ������擾
 *  get_location_upd_prdct      F  V     ���ݒn�iHZ_LOCATIONS�j�X�V���̒ǉ������擾
 *  get_account_ins_prdct       F  V     �A�J�E���g�iHZ_CUST_ACCOUNTS�j�쐬���̒ǉ������擾
 *  get_account_upd_prdct       F  V     �A�J�E���g�iHZ_CUST_ACCOUNTS�j�X�V���̒ǉ������擾
 *  get_acct_site_ins_prdct     F  V     �A�J�E���g�E�T�C�g�iHZ_CUST_ACCT_SITES_ALL�j�쐬���̒ǉ������擾
 *  get_site_use_ins_prdct      F  V     �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�쐬���̒ǉ������擾
 *  get_site_use_upd_prdct      F  V     �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�X�V���̒ǉ������擾
 *  get_site_use_del_prdct      F  V     �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�폜���̒ǉ������擾
 *  get_lead_upd_prdct          F  V     ���k�iAS_LEADS_ALL�j�X�V���̒ǉ������擾
 *  get_task_ins_prdct          F  V     �^�X�N�iJTF_TASKS_B�j�쐬���̒ǉ������擾
 *  get_task_upd_prdct          F  V     �^�X�N�iJTF_TASKS_B�j�X�V���̒ǉ������擾
 *  get_task_del_prdct          F  V     �^�X�N�iJTF_TASKS_B�j�폜���̒ǉ������擾
 *  chk_party_upd_enabled       F  V     �p�[�e�B�iHZ_PARTIES�j�X�V�\�`�F�b�N
 *  chk_org_pro_ext_ins_enabled F  V     �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j
 *                                       �쐬�\�`�F�b�N
 *  chk_org_pro_ext_upd_enabled F  V     �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j
 *                                       �X�V�\�`�F�b�N
 *  chk_org_pro_ext_del_enabled F  V     �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j
 *                                       �폜�\�`�F�b�N
 *  chk_location_upd_enabled    F  V     ���ݒn�iHZ_LOCATIONS�j�X�V�\�`�F�b�N
 *  chk_account_ins_enabled     F  V     �A�J�E���g�iHZ_CUST_ACCOUNTS�j�쐬�\�`�F�b�N
 *  chk_account_upd_enabled     F  V     �A�J�E���g�iHZ_CUST_ACCOUNTS�j�X�V�\�`�F�b�N
 *  chk_acct_site_ins_enabled   F  V     �A�J�E���g�E�T�C�g�iHZ_CUST_ACCT_SITES_ALL�j
 *                                       �쐬�\�`�F�b�N
 *  chk_site_use_ins_enabled    F  V     �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�쐬�\�`�F�b�N
 *  chk_site_use_upd_enabled    F  V     �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�X�V�\�`�F�b�N
 *  chk_site_use_del_enabled    F  V     �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�폜�\�`�F�b�N
 *  chk_lead_upd_enabled        F  V     ���k�iAS_LEADS_ALL�j�X�V�\�`�F�b�N
 *  chk_task_ins_enabled        F  V     �^�X�N�iJTF_TASKS_B�j�쐬�\�`�F�b�N
 *  chk_task_upd_enabled        F  V     �^�X�N�iJTF_TASKS_B�j�X�V�\�`�F�b�N
 *  chk_task_del_enabled        F  V     �^�X�N�iJTF_TASKS_B�j�폜�\�`�F�b�N
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   H.Ogawa          �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  -- �p�[�e�B�iHZ_PARTIES�j�X�V���̒ǉ������擾
  FUNCTION get_party_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�쐬���̒ǉ������擾
  FUNCTION get_org_pro_ext_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�X�V���̒ǉ������擾
  FUNCTION get_org_pro_ext_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�폜���̒ǉ������擾
  FUNCTION get_org_pro_ext_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���ݒn�iHZ_LOCATIONS�j�X�V���̒ǉ������擾
  FUNCTION get_location_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �A�J�E���g�iHZ_CUST_ACCOUNTS�j�쐬���̒ǉ������擾
  FUNCTION get_account_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �A�J�E���g�iHZ_CUST_ACCOUNTS�j�X�V���̒ǉ������擾
  FUNCTION get_account_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �A�J�E���g�E�T�C�g�iHZ_CUST_ACCT_SITES_ALL�j�쐬���̒ǉ������擾
  FUNCTION get_acct_site_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�쐬���̒ǉ������擾
  FUNCTION get_site_use_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�X�V���̒ǉ������擾
  FUNCTION get_site_use_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�폜���̒ǉ������擾
  FUNCTION get_site_use_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���k�iAS_LEADS_ALL�j�X�V���̒ǉ������擾
  FUNCTION get_lead_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �^�X�N�iJTF_TASKS_B�j�쐬���̒ǉ������擾
  FUNCTION get_task_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �^�X�N�iJTF_TASKS_B�j�X�V���̒ǉ������擾
  FUNCTION get_task_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �^�X�N�iJTF_TASKS_B�j�폜���̒ǉ������擾
  FUNCTION get_task_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �p�[�e�B�iHZ_PARTIES�j�X�V�\�`�F�b�N
  FUNCTION chk_party_upd_enabled(
    in_party_id            IN  NUMBER
   ,iv_duns_number_c       IN  VARCHAR2
   ,in_created_by          IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�쐬�\�`�F�b�N
  FUNCTION chk_org_pro_ext_ins_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�X�V�\�`�F�b�N
  FUNCTION chk_org_pro_ext_upd_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �g�D�v���t�@�C���g���iHZ_ORG_PROFILES_EXT_B�j�폜�\�`�F�b�N
  FUNCTION chk_org_pro_ext_del_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���ݒn�iHZ_LOCATIONS�j�X�V�\�`�F�b�N
  FUNCTION chk_location_upd_enabled(
    in_location_id         IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �A�J�E���g�iHZ_CUST_ACCOUNTS�j�쐬�\�`�F�b�N
  FUNCTION chk_account_ins_enabled(
    in_party_id            IN  NUMBER
   ,in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �A�J�E���g�iHZ_CUST_ACCOUNTS�j�X�V�\�`�F�b�N
  FUNCTION chk_account_upd_enabled(
    in_party_id            IN  NUMBER
   ,in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �A�J�E���g�E�T�C�g�iHZ_CUST_ACCT_SITES_ALL�j�쐬�\�`�F�b�N
  FUNCTION chk_acct_site_ins_enabled(
    in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�쐬�\�`�F�b�N
  FUNCTION chk_site_use_ins_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�X�V�\�`�F�b�N
  FUNCTION chk_site_use_upd_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �T�C�g�g�p�ړI�iHZ_CUST_SITE_USES_ALL�j�폜�\�`�F�b�N
  FUNCTION chk_site_use_del_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- ���k�iAS_LEADS_ALL�j�X�V�\�`�F�b�N
  FUNCTION chk_lead_upd_enabled(
    in_customer_id         IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- �^�X�N�iJTF_TASKS_B�j�쐬�\�`�F�b�N
  FUNCTION chk_task_ins_enabled(
    in_source_object_id    IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �^�X�N�iJTF_TASKS_B�j�X�V�\�`�F�b�N
  FUNCTION chk_task_upd_enabled(
    in_owner_id            IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �^�X�N�iJTF_TASKS_B�j�폜�\�`�F�b�N
  FUNCTION chk_task_del_enabled(
    in_owner_id            IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2;
--
END xxcso_009002j_pkg;
/
