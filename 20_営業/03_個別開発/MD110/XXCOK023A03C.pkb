CREATE OR REPLACE PACKAGE BODY XXCOK023A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A03C(body)
 * Description      : �^����\�Z�y�щ^������т����_�ʕi�ڕʁi�P�i�ʁj���ʂ�CSV�f�[�^�`���ŗv���o�͂��܂��B
 * MD.050           : �^����\�Z�ꗗ�\�o�� MD050_COK_023_A03
 * Version          : 2.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  put_base_sum_data     ���_�v�f�[�^�o�͏���(A-8)
 *  edit_base_sum_data    ���_�v�f�[�^�ҏW����(A-7)
 *  put_line_data         ���׃f�[�^�o�͏���(A-6)
 *  edit_line_data        ���׃f�[�^�ҏW����(A-5)
 *  put_head_data         �w�b�_�o�͏���(A-4)
 *  get_line_data         ���׃f�[�^�擾����(A-3)
 *  get_base_data         ���_���o����(A-2)
 *  init                  ��������(A-1)
 *  submain               ���C�������v���V�[�W��
 *  main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.0   SCS T.Taniguchi  �V�K�쐬
 *  2009/02/06    1.1   SCS T.Taniguchi  [��QCOK_017] �N�C�b�N�R�[�h�r���[�̗L�����E�������̔���ǉ�
 *  2009/03/02    1.2   SCS T.Taniguchi  [��QCOK_069] ���̓p�����[�^�u�E�Ӄ^�C�v�v�ɂ��A���_�̎擾�͈͂𐧌�
 *  2009/05/15    1.3   SCS A.Yano       [��QT1_1001] �o�͂������z�P�ʂ��~�ɏC��
 *  2009/09/03    1.4   SCS S.Moriyama   [��Q0001257] OPM�i�ڃ}�X�^�擾�����ǉ�
 *  2009/10/02    1.5   SCS S.Moriyama   [��QE_T3_00630] VDBM�c���ꗗ�\���o�͂���Ȃ��i���ޕs������j
 *  2009/12/07    1.6   SCS K.Nakamura   [��QE_�{�ғ�_00022] PT�Ή��i�i�ڃJ�e�S�����琭��Q�R�[�h���擾�j
 *  2010/01/29    2.0   SCS K.Kiriu      [��QE_�{�ғ�_01218] �\�Z�̂Ȃ����т��o�͂���悤�ɏC��(���ς�)
 *
 *****************************************************************************************/
--
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1) := '.';
-- �O���[�o���ϐ�
  gv_out_msg              VARCHAR2(2000) DEFAULT NULL;
  gn_target_cnt           NUMBER DEFAULT 0;       -- �Ώی���
  gn_normal_cnt           NUMBER DEFAULT 0;       -- ���팏��
  gn_error_cnt            NUMBER DEFAULT 0;       -- �G���[����
  gn_warn_cnt             NUMBER DEFAULT 0;       -- �X�L�b�v����
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCOK023A03C'; -- �p�b�P�[�W��
  -- application_short_name
  cv_appl_name_xxcok        CONSTANT VARCHAR2(5)  := 'XXCOK';        -- �A�v���P�[�V�����V���[�g�l�[��(XXCOK)
  cv_appl_name_xxccp        CONSTANT VARCHAR2(5)  := 'XXCCP';        -- �A�v���P�[�V�����V���[�g�l�[��(XXCCP)
  -- ���b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- �G���[�I�����b�Z�[�W
  cv_msg_xxccp1_90000       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- �Ώی����o��
  cv_msg_xxccp1_90001       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- ���������o��
  cv_msg_xxccp1_90002       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- �G���[�����o��
  cv_msg_xxccp1_90003       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- �X�L�b�v�����o��
  cv_msg_xxcok1_10184       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10184'; -- �Ώۃf�[�^����
  cv_msg_xxcok1_00003       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003'; -- �v���t�@�C���擾�G���[
  cv_msg_xxcok1_00013       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00013'; -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcok1_00052       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00052'; -- �E��ID�擾�G���[
  cv_msg_xxcok1_10182       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10182'; -- ���_�擾�G���[
  cv_msg_xxcok1_10183       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10183'; -- ���i���擾�G���[
  cv_msg_xxcok1_00018       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00018'; -- �R���J�����g���̓p�����[�^(���_�R�[�h)
  cv_msg_xxcok1_00019       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00019'; -- �R���J�����g���̓p�����[�^2(�\�Z�N�x)
  cv_msg_xxcok1_00012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00012'; -- �������_�G���[
  cv_msg_xxcok1_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015'; -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- �Ɩ��������t�擾�G���[
  -- �g�[�N��
  cv_year                   CONSTANT VARCHAR2(4)  := 'YEAR';             -- �\�Z�N�x
  cv_resp_name              CONSTANT VARCHAR2(9)  := 'RESP_NAME';        -- �E�Ӗ�
  cv_profile                CONSTANT VARCHAR2(7)  := 'PROFILE';          -- �v���t�@�C���E�I�v�V������
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';    -- ���_�R�[�h
  cv_item_code              CONSTANT VARCHAR2(9)  := 'ITEM_CODE';        -- �i�ڃR�[�h
  cv_org_code               CONSTANT VARCHAR2(8)  := 'ORG_CODE';         -- �݌ɑg�D�R�[�h
  cv_count                  CONSTANT VARCHAR2(5)  := 'COUNT';            -- ��������
  cv_user_id                CONSTANT VARCHAR2(7)  := 'USER_ID';          -- ���[�U�[ID
  cv_token_lookup_value_set CONSTANT VARCHAR2(16) := 'LOOKUP_VALUE_SET'; -- �N�C�b�N�R�[�h
  -- �J�X�^���E�v���t�@�C��
  cv_pro_organization_code  CONSTANT VARCHAR2(21)  := 'XXCOK1_ORG_CODE_SALES';    -- �݌ɑg�D�R�[�h
  cv_pro_head_office_code   CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF2_DEPT_HON';     -- �{�Ђ̕���R�[�h
  cv_pro_policy_group_code  CONSTANT VARCHAR2(24)  := 'XXCOK1_POLICY_GROUP_CODE'; -- ����Q�R�[�h
  -- �l�Z�b�g��
  cv_flex_st_name_dept      CONSTANT VARCHAR2(15)  := 'XX03_DEPARTMENT';          -- ����
  -- �Q�ƃ^�C�v
  cv_lookup_type_put_val    CONSTANT VARCHAR2(28)  := 'XXCOK1_COST_BUDGET_PUT_VALUE'; -- �^����\�Z�ꗗ�\���o��
  cv_lookup_type_month_c    CONSTANT VARCHAR2(26)  := 'XXCOK1_DVL_COST_MONTH_CALC';   -- �^����ʌv�Z�p
  -- �Q�ƃ^�C�v�R�[�h
  cv_lookup_code_month_c    CONSTANT VARCHAR2(1)   := '1';
  -- ����
  cv_lang                   CONSTANT VARCHAR2(4)   := USERENV('LANG');
  -- ���_�擾�p
  cv_cust_cd_base           CONSTANT VARCHAR2(1)   := '1';                  -- �ڋq�敪('1':���_)
  cv_put_code_line          CONSTANT VARCHAR2(1)   := '1';                  -- �o�͋敪('1':����)
  cv_put_code_sum           CONSTANT VARCHAR2(1)   := '2';                  -- �o�͋敪('2':���_�v)
  cv_resp_type_0            CONSTANT VARCHAR2(1)   := '0';                  -- ��Ǖ����S���ҐE��
  cv_resp_type_1            CONSTANT VARCHAR2(1)   := '1';                  -- �{������S���ҐE��
  cv_resp_type_2            CONSTANT VARCHAR2(1)   := '2';                  -- ���_����_�S���ҐE��
  cv_resp_name_val          CONSTANT VARCHAR2(100) := fnd_global.resp_name; -- �E�Ӗ�
  -- ���׃f�[�^�擾�p
  cv_kbn_koguchi            CONSTANT VARCHAR2(1)   := '1';          -- �����敪('1':����)
  cv_kbn_syatate            CONSTANT VARCHAR2(1)   := '0';          -- �����敪('0':�ԗ�)
  cv_month01                CONSTANT VARCHAR2(2)   := '01';         -- 1��(���т̔N�x�f�[�^�擾�p)
  cn_round                  CONSTANT NUMBER        := -3;           -- ���z�ۂߌ��ʒu
  cn_unit_amt               CONSTANT NUMBER        := 1000;         -- ���z�\���P��(1/1000)
  --���o���`�F�b�N�p
  cn_heading_cnt            CONSTANT NUMBER(2)     := 13;           -- ���o�����ڐ�
  -- ���̑�
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';          -- �t���O('Y')
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';          -- �t���O('N')
  cn_number_0               CONSTANT NUMBER        := 0;            -- ���l(0)
  cn_number_1               CONSTANT NUMBER        := 1;            -- ���l(1)
  cv_yyyymmdd               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD'; -- ���t�t�H�[�}�b�g
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';          -- �J���}
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_base_code            VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̋��_�R�[�h
  gv_budget_year          VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̗\�Z�N�x
  gv_org_code             VARCHAR2(3)  DEFAULT NULL; -- �݌ɑg�D�R�[�h
  gv_head_office_code     VARCHAR2(4)  DEFAULT NULL; -- �{�Е���R�[�h
  gv_policy_group_code    VARCHAR2(12) DEFAULT NULL; -- ����Q�R�[�h
  gn_org_id               NUMBER       DEFAULT NULL; -- �݌ɑg�DID
  gn_resp_id              NUMBER       DEFAULT NULL; -- ���O�C���E��ID
  gn_user_id              NUMBER       DEFAULT NULL; -- ���O�C�����[�U�[ID
  gn_put_count            NUMBER       DEFAULT 0;    -- ���׏o�̓J�E���g
  gd_process_date         DATE         DEFAULT NULL; -- �Ɩ��������t
  gv_resp_type            VARCHAR2(1)  DEFAULT NULL; -- �E�Ӄ^�C�v
  gv_month_f              VARCHAR2(2)  DEFAULT NULL; -- ������(���т̔N�x�f�[�^�擾�p)
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --���׃f�[�^�J�[�\��(�i�ڕʉȖڕʉ^����\�Z����)
  CURSOR get_cost_cur(
    iv_base_code IN VARCHAR2 )
  IS
    SELECT cost.item_code                   AS item_code,      -- �i�ڃR�[�h
           item.item_short_name             AS item_name,      -- �i�ږ���
           cost.line_num                    AS line_num,       -- ���הԍ�(1:����(�ԗ�) 2:����(����) 3:�\�Z)
           SUM(cost.qty_1)                  AS qty_month1,     -- ���񐔗�
           SUM(cost.amt_1)                  AS amt_month1,     -- ������z
           SUM(cost.qty_2)                  AS qty_month2,     -- 2����
           SUM(cost.amt_2)                  AS amt_month2,     -- 2���z
           SUM(cost.qty_3)                  AS qty_month3,     -- 3����
           SUM(cost.amt_3)                  AS amt_month3,     -- 3���z
           SUM(cost.qty_4)                  AS qty_month4,     -- 4����
           SUM(cost.amt_4)                  AS amt_month4,     -- 4���z
           SUM(cost.qty_5)                  AS qty_month5,     -- 5����
           SUM(cost.amt_5)                  AS amt_month5,     -- 5���z
           SUM(cost.qty_6)                  AS qty_month6,     -- 6����
           SUM(cost.amt_6)                  AS amt_month6,     -- 6���z
           SUM( cost.qty_1 + cost.qty_2 +
                cost.qty_3 + cost.qty_4 +
                cost.qty_5 + cost.qty_6 )   AS qty_first_half, -- ��������
           SUM( cost.amt_1 + cost.amt_2 +
                cost.amt_3 + cost.amt_4 +
                cost.amt_5 + cost.amt_6 )   AS amt_first_half, -- �������z
           SUM(cost.qty_7)                  AS qty_month7,     -- 7����
           SUM(cost.amt_7)                  AS amt_month7,     -- 7���z
           SUM(cost.qty_8)                  AS qty_month8,     -- 8����
           SUM(cost.amt_8)                  AS amt_month8,     -- 8���z
           SUM(cost.qty_9)                  AS qty_month9,     -- 9����
           SUM(cost.amt_9)                  AS amt_month9,     -- 9���z
           SUM(cost.qty_10)                 AS qty_month10,    -- 10����
           SUM(cost.amt_10)                 AS amt_month10,    -- 10���z
           SUM(cost.qty_11)                 AS qty_month11,    -- 11����
           SUM(cost.amt_11)                 AS amt_month11,    -- 11���z
           SUM(cost.qty_12)                 AS qty_month12,    -- 12����
           SUM(cost.amt_12)                 AS amt_month12,    -- 12���z
           SUM( cost.qty_1  + cost.qty_2  +
                cost.qty_3  + cost.qty_4  +
                cost.qty_5  + cost.qty_6  +
                cost.qty_7  + cost.qty_8  +
                cost.qty_9  + cost.qty_10 +
                cost.qty_11 + cost.qty_12 )  AS qty_year_sum,  -- �N�Ԍv����
           SUM( cost.amt_1  + cost.amt_2  +
                cost.amt_3  + cost.amt_4  +
                cost.amt_5  + cost.amt_6  +
                cost.amt_7  + cost.amt_8  +
                cost.amt_9  + cost.amt_10 +
                cost.amt_11 + cost.amt_12 )  AS amt_year_sum  -- �N�Ԍv���z
    FROM  (
           SELECT /*+
                      LEADING(flv)
                      INDEX(xdccb XXCOK_DLV_COST_CALC_BUDGET_N01)
                  */
                  xdccb.item_code              AS item_code,
                  3                            AS line_num,
                  DECODE( flv.attribute1
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_1,
                  ROUND( DECODE( flv.attribute1
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_1,
                  DECODE( flv.attribute2
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_2,
                  ROUND( DECODE( flv.attribute2
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_2,
                  DECODE( flv.attribute3
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_3,
                  ROUND( DECODE( flv.attribute3
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_3,
                  DECODE( flv.attribute4
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_4,
                  ROUND( DECODE( flv.attribute4
                                 ,xdccb.target_month, xdccb.dlv_cost_budget_amt
                                 ,0
                  ), cn_round ) / cn_unit_amt  AS amt_4,
                  DECODE( flv.attribute5
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_5,
                  ROUND( DECODE( flv.attribute5
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_5,
                  DECODE( flv.attribute6
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_6,
                  ROUND( DECODE( flv.attribute6
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_6,
                  DECODE( flv.attribute7
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_7,
                  ROUND( DECODE( flv.attribute7
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_7,
                  DECODE( flv.attribute8
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_8,
                  ROUND( DECODE( flv.attribute8
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_8,
                  DECODE( flv.attribute9
                         ,xdccb.target_month, xdccb.cs_qty
                         ,0
                  )                            AS qty_9,
                  ROUND( DECODE( flv.attribute9
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_9,
                  DECODE( flv.attribute10
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_10,
                  ROUND( DECODE( flv.attribute10
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_10,
                  DECODE( flv.attribute11
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_11,
                  ROUND( DECODE( flv.attribute11
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_11,
                  DECODE( flv.attribute12
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_12,
                  ROUND( DECODE( flv.attribute12
                                ,xdccb.target_month, xdccb.dlv_cost_budget_amt
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_12
           FROM   xxcok_dlv_cost_calc_budget xdccb,    -- �^����\�Z�e�[�u��
                  fnd_lookup_values          flv
           WHERE  xdccb.base_code     = iv_base_code   -- ���_�R�[�h
           AND    xdccb.budget_year   = gv_budget_year -- ���̓p�����[�^�̗\�Z�N�x
           AND    flv.lookup_type     = cv_lookup_type_month_c
           AND    flv.lookup_code     = cv_lookup_code_month_c
           AND    flv.enabled_flag    = cv_flag_y
           AND    flv.language        = cv_lang
           AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- �K�p�J�n��
           AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- �K�p�I����
           UNION ALL
           SELECT /*+
                      LEADING(flv)
                      INDEX(xdcrs1 xxcok_dlv_cost_result_sum_n01)
                  */
                  xdcrs1.item_code             AS item_code,
                  1                            AS line_num,
                  DECODE( flv.attribute1
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_1,
                  ROUND( DECODE( flv.attribute1
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_1,
                  DECODE( flv.attribute2
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_2,
                  ROUND( DECODE( flv.attribute2
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_2,
                  DECODE( flv.attribute3
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_3,
                  ROUND( DECODE( flv.attribute3
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_3,
                  DECODE( flv.attribute4
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_4,
                  ROUND( DECODE( flv.attribute4
                                 ,xdcrs1.target_month, xdcrs1.sum_amt
                                 ,0
                  ), cn_round ) / cn_unit_amt  AS amt_4,
                  DECODE( flv.attribute5
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_5,
                  ROUND( DECODE( flv.attribute5
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_5,
                  DECODE( flv.attribute6
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_6,
                  ROUND( DECODE( flv.attribute6
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_6,
                  DECODE( flv.attribute7
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_7,
                  ROUND( DECODE( flv.attribute7
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_7,
                  DECODE( flv.attribute8
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_8,
                  ROUND( DECODE( flv.attribute8
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_8,
                  DECODE( flv.attribute9
                         ,xdcrs1.target_month, xdcrs1.sum_cs_qty
                         ,0
                  )                            AS qty_9,
                  ROUND( DECODE( flv.attribute9
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_9,
                  DECODE( flv.attribute10
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_10,
                  ROUND( DECODE( flv.attribute10
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_10,
                  DECODE( flv.attribute11
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_11,
                  ROUND( DECODE( flv.attribute11
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_11,
                  DECODE( flv.attribute12
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_12,
                  ROUND( DECODE( flv.attribute12
                                ,xdcrs1.target_month, xdcrs1.sum_amt
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_12
           FROM   xxcok_dlv_cost_result_sum  xdcrs1,  -- �^������ь��ʏW�v�e�[�u��
                  fnd_lookup_values          flv
           WHERE  xdcrs1.base_code          = iv_base_code  -- ���_�R�[�h
           AND    xdcrs1.target_year        = CASE
                                               WHEN xdcrs1.target_month BETWEEN cv_month01 AND gv_month_f THEN
                                                 TO_CHAR( gv_budget_year + 1 )  --���N
                                               ELSE
                                                 gv_budget_year                 --���N
                                              END           --�N�x��N�ɕϊ����Ĕ�r
           AND    xdcrs1.small_amt_type     = cv_kbn_syatate  --�ԗ�
           AND    flv.lookup_type           = cv_lookup_type_month_c
           AND    flv.lookup_code           = cv_lookup_code_month_c
           AND    flv.enabled_flag          = cv_flag_y
           AND    flv.language              = cv_lang
           AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- �K�p�J�n��
           AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- �K�p�I����
           UNION ALL
           SELECT /*+
                      LEADING(flv)
                      INDEX(xdcrs2 xxcok_dlv_cost_result_sum_n01)
                  */
                  xdcrs2.item_code             AS item_code,
                  2                            AS line_num,
                  DECODE( flv.attribute1
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_1,
                  ROUND( DECODE( flv.attribute1
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_1,
                  DECODE( flv.attribute2
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_2,
                  ROUND( DECODE( flv.attribute2
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_2,
                  DECODE( flv.attribute3
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_3,
                  ROUND( DECODE( flv.attribute3
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_3,
                  DECODE( flv.attribute4
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_4,
                  ROUND( DECODE( flv.attribute4
                                 ,xdcrs2.target_month, xdcrs2.sum_amt
                                 ,0
                  ), cn_round ) / cn_unit_amt  AS amt_4,
                  DECODE( flv.attribute5
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_5,
                  ROUND( DECODE( flv.attribute5
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_5,
                  DECODE( flv.attribute6
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_6,
                  ROUND( DECODE( flv.attribute6
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_6,
                  DECODE( flv.attribute7
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_7,
                  ROUND( DECODE( flv.attribute7
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_7,
                  DECODE( flv.attribute8
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_8,
                  ROUND( DECODE( flv.attribute8
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_8,
                  DECODE( flv.attribute9
                         ,xdcrs2.target_month, xdcrs2.sum_cs_qty
                         ,0
                  )                            AS qty_9,
                  ROUND( DECODE( flv.attribute9
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_9,
                  DECODE( flv.attribute10
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_10,
                  ROUND( DECODE( flv.attribute10
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_10,
                  DECODE( flv.attribute11
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_11,
                  ROUND( DECODE( flv.attribute11
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_11,
                  DECODE( flv.attribute12
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_12,
                  ROUND( DECODE( flv.attribute12
                                ,xdcrs2.target_month, xdcrs2.sum_amt
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_12
           FROM   xxcok_dlv_cost_result_sum  xdcrs2,  -- �^������ь��ʏW�v�e�[�u��
                  fnd_lookup_values          flv
           WHERE  xdcrs2.base_code          = iv_base_code  -- ���_�R�[�h
           AND    xdcrs2.target_year        = CASE
                                               WHEN xdcrs2.target_month BETWEEN cv_month01 AND gv_month_f THEN
                                                 TO_CHAR( gv_budget_year + 1 )  --���N
                                               ELSE
                                                 gv_budget_year                 --���N
                                              END          --�N�x��N�ɕϊ����Ĕ�r
           AND    xdcrs2.small_amt_type     = cv_kbn_koguchi  --����
           AND    flv.lookup_type           = cv_lookup_type_month_c
           AND    flv.lookup_code           = cv_lookup_code_month_c
           AND    flv.enabled_flag          = cv_flag_y
           AND    flv.language              = cv_lang
           AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- �K�p�J�n��
           AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- �K�p�I����
       ) cost,
       (SELECT /*+
                   USE_NL( msib,iimc,ximb )
                   USE_NL( mic,mcb,mcsb,mcst )
               */
               iimb.item_no,                      -- �i�ڃR�[�h
               ximb.item_short_name,              -- ����
               SUBSTRB( mcb.segment1,1,3 ) AS policy_group_code -- ����Q�R�[�h
        FROM   ic_item_mst_b              iimb,   -- opm�i�ڃ}�X�^
               xxcmn_item_mst_b           ximb,   -- opm�i�ڃA�h�I���}�X�^
               mtl_system_items_b         msib,   -- �i�ڃ}�X�^
               mtl_category_sets_b        mcsb,   -- �i�ڃJ�e�S���Z�b�g
               mtl_category_sets_tl       mcst,   -- �i�ڃJ�e�S���Z�b�g���{��
               mtl_categories_b           mcb ,   -- �i�ڃJ�e�S���}�X�^
               mtl_item_categories        mic     -- �i�ڃJ�e�S������
        WHERE  ximb.item_id           = iimb.item_id
        AND    iimb.item_no           = msib.segment1
        AND    msib.organization_id   = gn_org_id
        AND    mcst.category_set_id   = mcsb.category_set_id
        AND    mcb.structure_id       = mcsb.structure_id
        AND    mcb.category_id        = mic.category_id
        AND    mcsb.category_set_id   = mic.category_set_id
        AND    mcst.language          = cv_lang
        AND    mcst.category_set_name = gv_policy_group_code
        AND    mcb.segment1           IS NOT NULL
        AND    msib.organization_id   = mic.organization_id
        AND    msib.inventory_item_id = mic.inventory_item_id
        AND    gd_process_date BETWEEN ximb.start_date_active
                                               AND NVL ( ximb.end_date_active , gd_process_date )
        )item
    WHERE cost.item_code   = item.item_no(+)
    GROUP BY
          item.policy_group_code, -- ����Q�R�[�h
          cost.item_code,         -- �i�ڃR�[�h
          item.item_short_name,   -- �i�ږ���
          cost.line_num           -- ���הԍ�
    ORDER BY
          item.policy_group_code, -- ����Q�R�[�h
          cost.item_code,         -- �i�ڃR�[�h
          cost.line_num           -- ���הԍ�(1:����(�ԗ�) 2:����(����) 3:�\�Z)
  ;
  -- ���o���擾�J�[�\��
  CURSOR put_value_cur
  IS
    SELECT flv.attribute1 AS put_val
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type                               = cv_lookup_type_put_val
    AND    flv.enabled_flag                              = cv_flag_y
    AND    flv.language                                  = cv_lang
    AND    NVL( flv.start_date_active,gd_process_date ) <= gd_process_date  -- �K�p�J�n��
    AND    NVL( flv.end_date_active,gd_process_date )   >= gd_process_date  -- �K�p�I����
    ORDER BY
           TO_NUMBER(flv.lookup_code)
  ;
--
  -- ===============================
  -- ���R�[�h�^�C�v�̐錾��
  -- ===============================
--
  -- ���_���̃��R�[�h�^�C�v
  TYPE base_rec IS RECORD(
    base_code        VARCHAR2(4), -- ���_�R�[�h
    base_name        VARCHAR2(50) -- ���_��
  );
--
  -- ===============================
  -- �e�[�u���^�C�v�̐錾��
  -- ===============================
--
  -- ���o���̃e�[�u���^�C�v
  TYPE put_value_ttype IS TABLE OF put_value_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  -- ���_���̃e�[�u���^�C�v
  TYPE base_ttype IS TABLE OF base_rec INDEX BY BINARY_INTEGER;
  -- ���׃f�[�^�̃e�[�u���^�C�v
  TYPE get_cost_ttype is TABLE OF get_cost_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--
  g_put_value_tab      put_value_ttype;    -- ���o��
  g_base_tab           base_ttype;         -- ���_���
  g_cost_line_tab      get_cost_ttype;     -- ���׃f�[�^
  g_cost_base_sum_tab  get_cost_ttype;     -- ���_�v�f�[�^
  g_cost_dummy_tab     get_cost_ttype;     -- �_�~�[�p
--
  /**********************************************************************************
   * Procedure Name   : put_base_sum_data
   * Description      : ���_�v�f�[�^�o�͏���(A-8)
   ***********************************************************************************/
  PROCEDURE put_base_sum_data(
    ov_errbuf            OUT VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(17) := 'put_base_sum_data'; -- �v���O������
--
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���ϐ� ***
    lb_retcode        BOOLEAN        DEFAULT TRUE;  -- ���b�Z�[�W�o�͊֐��߂�l
    lv_put_value_amt  VARCHAR2(500);                -- �o�͕ҏW�p
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    --����(�ԗ�)�A����(����)�A�\�Z�A���ьv�A�\-����5�s�����[�v���o��
    <<put_base_sum_loop>>
    FOR i IN 1 .. g_cost_base_sum_tab.COUNT LOOP
--
      -- ���_�v�e�s�̌��o���̕ҏW
      IF ( i = 1 ) THEN
        lv_put_value_amt := g_put_value_tab(9).put_val;   --���o��(�ԗ�)
      ELSIF ( i = 2 ) THEN
        lv_put_value_amt := g_put_value_tab(10).put_val;  --���o��(����)
      ELSIF ( i = 3 ) THEN
        lv_put_value_amt := g_put_value_tab(11).put_val;  --���o��(�\�Z)
      ELSIF ( i = 4 ) THEN
        lv_put_value_amt := g_put_value_tab(12).put_val;  --���o��(����)
      ELSIF ( i = 5 ) THEN
        lv_put_value_amt := g_put_value_tab(13).put_val;  --���o��(�\�Z-����)
      END IF;
--
      -- ���o��+���z�̕ҏW
      lv_put_value_amt := lv_put_value_amt                               || cv_comma ||  -- ���o��
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month1)     || cv_comma ||  -- ������z
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month2)     || cv_comma ||  -- 2
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month3)     || cv_comma ||  -- 3
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month4)     || cv_comma ||  -- 4
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month5)     || cv_comma ||  -- 5
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month6)     || cv_comma ||  -- 6
                          TO_CHAR(g_cost_base_sum_tab(i).amt_first_half) || cv_comma ||  -- �������z
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month7)     || cv_comma ||  -- 7
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month8)     || cv_comma ||  -- 8
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month9)     || cv_comma ||  -- 9
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month10)    || cv_comma ||  -- 10
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month11)    || cv_comma ||  -- 11
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month12)    || cv_comma ||  -- 12
                          TO_CHAR(g_cost_base_sum_tab(i).amt_year_sum)                   -- �N�Ԍv���z
                          ;
--
      -- �o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT,
                      iv_message  => lv_put_value_amt,  -- �o�̓f�[�^
                      in_new_line => cn_number_0        -- ���s��
                    );
--
    END LOOP put_base_sum_loop;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_base_sum_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_base_sum_data
   * Description      : ���_�v�f�[�^�ҏW����(A-7)
   ***********************************************************************************/
  PROCEDURE edit_base_sum_data(
    ov_errbuf            OUT VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2,       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_process_flag      IN  NUMBER,         -- �����t���O(0:������ 1:���ב�������)
    i_cost_base_sum_tab  IN  get_cost_ttype) -- ���א��ʁE���z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(18) := 'edit_base_sum_data'; -- �v���O������
--
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- �������̏ꍇ
    IF ( iv_process_flag = cn_number_0 ) THEN
--
      -- ����(�ԗ�)�A����(����)�A�\�Z�A���ьv�A�\-����5�s�����[�v
      <<item_init_loop>>
      FOR i IN 1 .. 5 LOOP
        -- ���_�v�p�e�[�u���ϐ��̏�����(�p�����[�^�Ƀ_�~�[���ݒ肳��Ă���ׁA���z0�ƂȂ�)
        g_cost_base_sum_tab(i).amt_month1     := i_cost_base_sum_tab(1).amt_month1;
        g_cost_base_sum_tab(i).amt_month2     := i_cost_base_sum_tab(1).amt_month2;
        g_cost_base_sum_tab(i).amt_month3     := i_cost_base_sum_tab(1).amt_month3;
        g_cost_base_sum_tab(i).amt_month4     := i_cost_base_sum_tab(1).amt_month4;
        g_cost_base_sum_tab(i).amt_month5     := i_cost_base_sum_tab(1).amt_month5;
        g_cost_base_sum_tab(i).amt_month6     := i_cost_base_sum_tab(1).amt_month6;
        g_cost_base_sum_tab(i).amt_first_half := i_cost_base_sum_tab(1).amt_first_half;
        g_cost_base_sum_tab(i).amt_month7     := i_cost_base_sum_tab(1).amt_month7;
        g_cost_base_sum_tab(i).amt_month8     := i_cost_base_sum_tab(1).amt_month8;
        g_cost_base_sum_tab(i).amt_month9     := i_cost_base_sum_tab(1).amt_month9;
        g_cost_base_sum_tab(i).amt_month10    := i_cost_base_sum_tab(1).amt_month10;
        g_cost_base_sum_tab(i).amt_month11    := i_cost_base_sum_tab(1).amt_month11;
        g_cost_base_sum_tab(i).amt_month12    := i_cost_base_sum_tab(1).amt_month12;
        g_cost_base_sum_tab(i).amt_year_sum   := i_cost_base_sum_tab(1).amt_year_sum;
      END LOOP item_init_loop;
--
    -- ���ב������݂̏ꍇ
    ELSIF ( iv_process_flag = cn_number_1 ) THEN
--
      -- ����(�ԗ�)�A����(����)�A�\�Z�A���ьv�A�\-����5�s�����[�v
      <<base_sum_loop>>
      FOR i IN 1 .. i_cost_base_sum_tab.COUNT LOOP
        -- ���׍s�̑�������
        g_cost_base_sum_tab(i).amt_month1     := g_cost_base_sum_tab(i).amt_month1     + i_cost_base_sum_tab(i).amt_month1;
        g_cost_base_sum_tab(i).amt_month2     := g_cost_base_sum_tab(i).amt_month2     + i_cost_base_sum_tab(i).amt_month2;
        g_cost_base_sum_tab(i).amt_month3     := g_cost_base_sum_tab(i).amt_month3     + i_cost_base_sum_tab(i).amt_month3;
        g_cost_base_sum_tab(i).amt_month4     := g_cost_base_sum_tab(i).amt_month4     + i_cost_base_sum_tab(i).amt_month4;
        g_cost_base_sum_tab(i).amt_month5     := g_cost_base_sum_tab(i).amt_month5     + i_cost_base_sum_tab(i).amt_month5;
        g_cost_base_sum_tab(i).amt_month6     := g_cost_base_sum_tab(i).amt_month6     + i_cost_base_sum_tab(i).amt_month6;
        g_cost_base_sum_tab(i).amt_first_half := g_cost_base_sum_tab(i).amt_first_half + i_cost_base_sum_tab(i).amt_first_half;
        g_cost_base_sum_tab(i).amt_month7     := g_cost_base_sum_tab(i).amt_month7     + i_cost_base_sum_tab(i).amt_month7;
        g_cost_base_sum_tab(i).amt_month8     := g_cost_base_sum_tab(i).amt_month8     + i_cost_base_sum_tab(i).amt_month8;
        g_cost_base_sum_tab(i).amt_month9     := g_cost_base_sum_tab(i).amt_month9     + i_cost_base_sum_tab(i).amt_month9;
        g_cost_base_sum_tab(i).amt_month10    := g_cost_base_sum_tab(i).amt_month10    + i_cost_base_sum_tab(i).amt_month10;
        g_cost_base_sum_tab(i).amt_month11    := g_cost_base_sum_tab(i).amt_month11    + i_cost_base_sum_tab(i).amt_month11;
        g_cost_base_sum_tab(i).amt_month12    := g_cost_base_sum_tab(i).amt_month12    + i_cost_base_sum_tab(i).amt_month12;
        g_cost_base_sum_tab(i).amt_year_sum   := g_cost_base_sum_tab(i).amt_year_sum   + i_cost_base_sum_tab(i).amt_year_sum;
      END LOOP base_sum_loop;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END edit_base_sum_data;
--
  /**********************************************************************************
   * Procedure Name   : put_line_data
   * Description      : ���׃f�[�^�o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE put_line_data(
    ov_errbuf           OUT   VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT   VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT   VARCHAR2,       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_item_code        IN    VARCHAR2,       -- �i�ڃR�[�h
    iv_item_name        IN    VARCHAR2,       -- �i�ږ���
    i_cost_tab          IN    get_cost_ttype) -- ���א��ʁE���z�f�[�^
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'put_line_data'; -- �v���O������
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lb_retcode        BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�͊֐��߂�l
    lv_put_value_qty  VARCHAR2(500);                 -- ���ʍs�̏o��
    lv_put_value_amt  VARCHAR2(500);                 -- ���z�s�̏o��
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ���׍s4�񕪃��[�v
    <<put_line_loop>>
    FOR i IN 1 .. i_cost_tab.COUNT LOOP
--
      -- �e�s�̌��o���̕ҏW
      IF ( i = 1 ) THEN
        -- ����(�ԗ�)�̐��ʍs
        lv_put_value_qty := iv_item_code                || cv_comma ||  --�i�ڃR�[�h
                            iv_item_name                ||              --�i�ږ���
                            g_put_value_tab(4).put_val                  --���o��(����(�ԗ�))
                            ;
      ELSIF ( i = 2 ) THEN
        -- ����(����)�̐��ʍs
        lv_put_value_qty := g_put_value_tab(6).put_val;                 --���o��(����(����))
      ELSIF ( i = 3 ) THEN
        -- �\�Z�̐��ʍs
        lv_put_value_qty := g_put_value_tab(7).put_val;                 --���o��(�\�Z)
      ELSIF ( i = 4 ) THEN
        -- ���ьv���ʍs
        lv_put_value_qty := g_put_value_tab(8).put_val;                 --���o��(���ьv)
      END IF;
--
      -- ���o��+���z�̕ҏW(���ʍs)
      lv_put_value_qty := lv_put_value_qty                      || cv_comma ||  --���o��(�ҏW��)
                          TO_CHAR(i_cost_tab(i).qty_month1)     || cv_comma ||  --���񐔗�
                          TO_CHAR(i_cost_tab(i).qty_month2)     || cv_comma ||  --2
                          TO_CHAR(i_cost_tab(i).qty_month3)     || cv_comma ||  --3
                          TO_CHAR(i_cost_tab(i).qty_month4)     || cv_comma ||  --4
                          TO_CHAR(i_cost_tab(i).qty_month5)     || cv_comma ||  --5
                          TO_CHAR(i_cost_tab(i).qty_month6)     || cv_comma ||  --6
                          TO_CHAR(i_cost_tab(i).qty_first_half) || cv_comma ||  --��������
                          TO_CHAR(i_cost_tab(i).qty_month7)     || cv_comma ||  --7
                          TO_CHAR(i_cost_tab(i).qty_month8)     || cv_comma ||  --8
                          TO_CHAR(i_cost_tab(i).qty_month9)     || cv_comma ||  --9
                          TO_CHAR(i_cost_tab(i).qty_month10)    || cv_comma ||  --10
                          TO_CHAR(i_cost_tab(i).qty_month11)    || cv_comma ||  --11
                          TO_CHAR(i_cost_tab(i).qty_month12)    || cv_comma ||  --12
                          TO_CHAR(i_cost_tab(i).qty_year_sum)                   --�N�Ԍv
                          ;
      -- ���o��+���z�̕ҏW(���z�s)
      lv_put_value_amt := g_put_value_tab(5).put_val            || cv_comma ||  --���o��(����)
                          TO_CHAR(i_cost_tab(i).amt_month1)     || cv_comma ||  --���񐔗�
                          TO_CHAR(i_cost_tab(i).amt_month2)     || cv_comma ||  --2
                          TO_CHAR(i_cost_tab(i).amt_month3)     || cv_comma ||  --3
                          TO_CHAR(i_cost_tab(i).amt_month4)     || cv_comma ||  --4
                          TO_CHAR(i_cost_tab(i).amt_month5)     || cv_comma ||  --5
                          TO_CHAR(i_cost_tab(i).amt_month6)     || cv_comma ||  --6
                          TO_CHAR(i_cost_tab(i).amt_first_half) || cv_comma ||  --��������
                          TO_CHAR(i_cost_tab(i).amt_month7)     || cv_comma ||  --7
                          TO_CHAR(i_cost_tab(i).amt_month8)     || cv_comma ||  --8
                          TO_CHAR(i_cost_tab(i).amt_month9)     || cv_comma ||  --9
                          TO_CHAR(i_cost_tab(i).amt_month10)    || cv_comma ||  --10
                          TO_CHAR(i_cost_tab(i).amt_month11)    || cv_comma ||  --11
                          TO_CHAR(i_cost_tab(i).amt_month12)    || cv_comma ||  --12
                          TO_CHAR(i_cost_tab(i).amt_year_sum)                   --�N�Ԍv
                          ;
--
      -- �o��(���ʍs)
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT,
                      iv_message  => lv_put_value_qty,  -- �o�̓f�[�^
                      in_new_line => cn_number_0        -- ���s��
                    );
      -- �o��(���z�s)
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT,
                      iv_message  => lv_put_value_amt,  -- �o�̓f�[�^
                      in_new_line => cn_number_0        -- ���s��
                    );
--
    END LOOP put_line_loop;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_line_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_line_data
   * Description      : ���׃f�[�^�ҏW����(A-5)
   ***********************************************************************************/
  PROCEDURE edit_line_data(
    ov_errbuf                   OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_item_code                IN  VARCHAR2 DEFAULT NULL, -- ���i�R�[�h
    iv_item_name                IN  VARCHAR2 DEFAULT NULL, -- ���i��(����)
    i_cost_tab                  IN  get_cost_ttype)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(14) := 'edit_line_data'; -- �v���O������
--
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���ϐ� ***
    lb_retcode      BOOLEAN        DEFAULT TRUE;  -- ���b�Z�[�W�o�͊֐��߂�l
    lv_result_s     VARCHAR2(1)    DEFAULT cv_flag_n;
    lv_result_k     VARCHAR2(1)    DEFAULT cv_flag_n;
    lv_budget       VARCHAR2(1)    DEFAULT cv_flag_n;
    -- *** ���[�J���e�[�u�� ***
    l_cost_line_tab get_cost_ttype;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- �Ώی����J�E���g(�i�ڒP�ʂׁ̈A�����ŃJ�E���g)
    gn_target_cnt := gn_target_cnt + 1;
--
    -----------------------------
    -- ���׍s�̕ҏW
    -----------------------------
    -- �i�ڂɎ���(�ԗ�)�A����(����)�A�\�Z�̍s�����݂��邩�`�F�b�N����
    <<line_check_loop>>
    FOR i IN 1.. i_cost_tab.COUNT LOOP
      -- ����(�ԗ�)�s�̑���
      IF ( i_cost_tab(i).line_num = 1 ) THEN
        lv_result_s        := cv_flag_y;
        l_cost_line_tab(1) := i_cost_tab(i);
      -- ����(����)�s�̑���
      ELSIF ( i_cost_tab(i).line_num = 2 ) THEN
        lv_result_k        := cv_flag_y;
        l_cost_line_tab(2) := i_cost_tab(i);
      -- �\�Z�s�̑���
      ELSIF ( i_cost_tab(i).line_num = 3 ) THEN
        lv_budget          := cv_flag_y;
        l_cost_line_tab(3) := i_cost_tab(i);
      END IF;
    END LOOP line_check_loop;
--
    --�e�s�����݂��Ȃ��ꍇ�A���݂��Ȃ��s�Ƀ_�~�[�s(�S��0�̍s)��ݒ肷��
    IF ( lv_result_s = cv_flag_n ) THEN
      l_cost_line_tab(1) := g_cost_dummy_tab(1);  --����(�ԗ�)�s
    END IF;
    IF ( lv_result_k = cv_flag_n ) THEN
      l_cost_line_tab(2) := g_cost_dummy_tab(1);  --����(����)�s
    END IF;
    IF ( lv_budget   = cv_flag_n ) THEN
      l_cost_line_tab(3) := g_cost_dummy_tab(1);  --�\�Z�s
    END IF;
--
    -- ���ьv(�ԗ�+����)�s�̕ҏW
    l_cost_line_tab(4).qty_month1     := l_cost_line_tab(1).qty_month1     + l_cost_line_tab(2).qty_month1;
    l_cost_line_tab(4).amt_month1     := l_cost_line_tab(1).amt_month1     + l_cost_line_tab(2).amt_month1;
    l_cost_line_tab(4).qty_month2     := l_cost_line_tab(1).qty_month2     + l_cost_line_tab(2).qty_month2;
    l_cost_line_tab(4).amt_month2     := l_cost_line_tab(1).amt_month2     + l_cost_line_tab(2).amt_month2;
    l_cost_line_tab(4).qty_month3     := l_cost_line_tab(1).qty_month3     + l_cost_line_tab(2).qty_month3;
    l_cost_line_tab(4).amt_month3     := l_cost_line_tab(1).amt_month3     + l_cost_line_tab(2).amt_month3;
    l_cost_line_tab(4).qty_month4     := l_cost_line_tab(1).qty_month4     + l_cost_line_tab(2).qty_month4;
    l_cost_line_tab(4).amt_month4     := l_cost_line_tab(1).amt_month4     + l_cost_line_tab(2).amt_month4;
    l_cost_line_tab(4).qty_month5     := l_cost_line_tab(1).qty_month5     + l_cost_line_tab(2).qty_month5;
    l_cost_line_tab(4).amt_month5     := l_cost_line_tab(1).amt_month5     + l_cost_line_tab(2).amt_month5;
    l_cost_line_tab(4).qty_month6     := l_cost_line_tab(1).qty_month6     + l_cost_line_tab(2).qty_month6;
    l_cost_line_tab(4).amt_month6     := l_cost_line_tab(1).amt_month6     + l_cost_line_tab(2).amt_month6;
    l_cost_line_tab(4).qty_first_half := l_cost_line_tab(1).qty_first_half + l_cost_line_tab(2).qty_first_half;
    l_cost_line_tab(4).amt_first_half := l_cost_line_tab(1).amt_first_half + l_cost_line_tab(2).amt_first_half;
    l_cost_line_tab(4).qty_month7     := l_cost_line_tab(1).qty_month7     + l_cost_line_tab(2).qty_month7;
    l_cost_line_tab(4).amt_month7     := l_cost_line_tab(1).amt_month7     + l_cost_line_tab(2).amt_month7;
    l_cost_line_tab(4).qty_month8     := l_cost_line_tab(1).qty_month8     + l_cost_line_tab(2).qty_month8;
    l_cost_line_tab(4).amt_month8     := l_cost_line_tab(1).amt_month8     + l_cost_line_tab(2).amt_month8;
    l_cost_line_tab(4).qty_month9     := l_cost_line_tab(1).qty_month9     + l_cost_line_tab(2).qty_month9;
    l_cost_line_tab(4).amt_month9     := l_cost_line_tab(1).amt_month9     + l_cost_line_tab(2).amt_month9;
    l_cost_line_tab(4).qty_month10    := l_cost_line_tab(1).qty_month10    + l_cost_line_tab(2).qty_month10;
    l_cost_line_tab(4).amt_month10    := l_cost_line_tab(1).amt_month10    + l_cost_line_tab(2).amt_month10;
    l_cost_line_tab(4).qty_month11    := l_cost_line_tab(1).qty_month11    + l_cost_line_tab(2).qty_month11;
    l_cost_line_tab(4).amt_month11    := l_cost_line_tab(1).amt_month11    + l_cost_line_tab(2).amt_month11;
    l_cost_line_tab(4).qty_month12    := l_cost_line_tab(1).qty_month12    + l_cost_line_tab(2).qty_month12;
    l_cost_line_tab(4).amt_month12    := l_cost_line_tab(1).amt_month12    + l_cost_line_tab(2).amt_month12;
    l_cost_line_tab(4).qty_year_sum   := l_cost_line_tab(1).qty_year_sum   + l_cost_line_tab(2).qty_year_sum;
    l_cost_line_tab(4).amt_year_sum   := l_cost_line_tab(1).amt_year_sum   + l_cost_line_tab(2).amt_year_sum;
--
    -- ==========================
    -- ���׃f�[�^�o�͏���
    -- ==========================
    put_line_data(
       ov_errbuf    => lv_errbuf
      ,ov_retcode   => lv_retcode
      ,ov_errmsg    => lv_errmsg
      ,iv_item_code => iv_item_code    -- �i�ڃR�[�h
      ,iv_item_name => iv_item_name    -- �i�ږ���
      ,i_cost_tab   => l_cost_line_tab -- �i�ږ��̖��א��ʁE���z�f�[�^
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���������J�E���g(�i�ڒP�ʂׁ̈A�����ŃJ�E���g)
    gn_normal_cnt := gn_normal_cnt + cn_number_1;
    -- ���׏o�͌����̎擾(�i�ڒP�ʂׁ̈A�����ŃJ�E���g)
    gn_put_count  := gn_put_count + cn_number_1;
--
    -----------------------------
    -- ���_�v�̕ҏW
    -----------------------------
    -- ���_�v(�\�Z-����)�s�̕ҏW
    l_cost_line_tab(5).amt_month1     := l_cost_line_tab(3).amt_month1     - l_cost_line_tab(4).amt_month1;
    l_cost_line_tab(5).amt_month2     := l_cost_line_tab(3).amt_month2     - l_cost_line_tab(4).amt_month2;
    l_cost_line_tab(5).amt_month3     := l_cost_line_tab(3).amt_month3     - l_cost_line_tab(4).amt_month3;
    l_cost_line_tab(5).amt_month4     := l_cost_line_tab(3).amt_month4     - l_cost_line_tab(4).amt_month4;
    l_cost_line_tab(5).amt_month5     := l_cost_line_tab(3).amt_month5     - l_cost_line_tab(4).amt_month5;
    l_cost_line_tab(5).amt_month6     := l_cost_line_tab(3).amt_month6     - l_cost_line_tab(4).amt_month6;
    l_cost_line_tab(5).amt_first_half := l_cost_line_tab(3).amt_first_half - l_cost_line_tab(4).amt_first_half;
    l_cost_line_tab(5).amt_month7     := l_cost_line_tab(3).amt_month7     - l_cost_line_tab(4).amt_month7;
    l_cost_line_tab(5).amt_month8     := l_cost_line_tab(3).amt_month8     - l_cost_line_tab(4).amt_month8;
    l_cost_line_tab(5).amt_month9     := l_cost_line_tab(3).amt_month9     - l_cost_line_tab(4).amt_month9;
    l_cost_line_tab(5).amt_month10    := l_cost_line_tab(3).amt_month10    - l_cost_line_tab(4).amt_month10;
    l_cost_line_tab(5).amt_month11    := l_cost_line_tab(3).amt_month11    - l_cost_line_tab(4).amt_month11;
    l_cost_line_tab(5).amt_month12    := l_cost_line_tab(3).amt_month12    - l_cost_line_tab(4).amt_month12;
    l_cost_line_tab(5).amt_year_sum   := l_cost_line_tab(3).amt_year_sum   - l_cost_line_tab(4).amt_year_sum;
--
    -- ==========================
    -- ���_�v�f�[�^�ҏW����
    -- ==========================
    edit_base_sum_data(
       ov_errbuf            => lv_errbuf
      ,ov_retcode           => lv_retcode
      ,ov_errmsg            => lv_errmsg
      ,iv_process_flag      => cn_number_1     -- �����t���O(1:���ב�������)
      ,i_cost_base_sum_tab  => l_cost_line_tab -- �i�ږ��̖��א��ʁE���z�f�[�^
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END edit_line_data;
--
  /**********************************************************************************
   * Procedure Name   : put_head_data
   * Description      : �w�b�_�f�[�^�o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE put_head_data(
    ov_errbuf     OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2, -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code  IN  VARCHAR2, -- ���_�R�[�h
    iv_base_name  IN  VARCHAR2) -- ���_��
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(13) := 'put_head_data'; -- �v���O������
--
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���ϐ� ***
    lb_retcode      BOOLEAN        DEFAULT TRUE;  -- ���b�Z�[�W�o�͊֐��߂�l
    lv_put_value_h  VARCHAR2(500);
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    ------------------------
    -- ���_�s�o��
    ------------------------
    -- ���_�f�[�^�ҏW
    lv_put_value_h := g_put_value_tab(1).put_val ||
                      iv_base_code               || cv_comma ||
                      iv_base_name
                      ;
    -- ���_�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT
                    ,iv_message  => lv_put_value_h     -- �o�̓f�[�^
                    ,in_new_line => cn_number_0        -- ���s��
                  );
    ------------------------
    -- �P�ʍs�o��
    ------------------------
    -- �P�ʍs�f�[�^�ҏW
    lv_put_value_h := g_put_value_tab(2).put_val;
    -- �P�ʍs�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT
                    ,iv_message  => lv_put_value_h     -- �o�̓f�[�^
                    ,in_new_line => cn_number_0        -- ���s��
                  );
    ------------------------
    -- ���ڌ��o���s�o��
    ------------------------
    -- ���ڌ��o���s�f�[�^�ҏW
    lv_put_value_h := g_put_value_tab(3).put_val;
    -- ���ڌ��o���s�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT
                    ,iv_message  => lv_put_value_h     -- �o�̓f�[�^
                    ,in_new_line => cn_number_0        -- ���s��
                  );
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_head_data;
--
  /**********************************************************************************
   * Procedure Name   : get_line_data
   * Description      : ���׃f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_line_data(
    ov_errbuf     OUT  VARCHAR2, -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT  VARCHAR2, -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT  VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_line_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lb_retcode    BOOLEAN                               DEFAULT TRUE; -- ���b�Z�[�W�o�͊֐��߂�l
    lt_item_code  ic_item_mst_b.item_no%TYPE;                         -- �i�ڃR�[�h�ێ��p
    lt_item_name  xxcmn_item_mst_b.item_short_name%TYPE;              -- �i�ږ��̕ێ��p
    ln_item_cnt   BINARY_INTEGER;                                     -- ���׃f�[�^�p�e�[�u��(����i��)�Y��
--
    -- *** ���[�J���e�[�u�� ***
    l_cost_l_item_tab  get_cost_ttype;                                -- ���׃f�[�^�p�e�[�u��(����i��)
--
    -- *** ���[�J����O ***
    no_data_expt  EXCEPTION;                                          -- �i�ږ��̃`�F�b�N��O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ���_���[�v
    <<base_loop>>
    FOR base_cnt IN 1 .. g_base_tab.COUNT LOOP
--
      -- ���_�P�ʂ̏�����
      g_cost_base_sum_tab.DELETE;  -- ���_�v�p�e�[�u��
      g_cost_line_tab.DELETE;      -- ���׃f�[�^�p�e�[�u��(���_�P�ʑS��)
      l_cost_l_item_tab.DELETE;    -- ���׃f�[�^�p�e�[�u��(����i��)
      ln_item_cnt    := 0;         -- ���׃f�[�^�p�e�[�u��(����i��)�Y��
      lt_item_code   := NULL;      -- �i�ڃR�[�h
      lt_item_name   := NULL;      -- �i�ږ���
      -- ===========================
      -- ���_�v�p�f�[�^�ҏW(������)
      -- ===========================
      edit_base_sum_data(
         ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
        ,iv_process_flag      => cn_number_0      -- �����t���O(0:������)
        ,i_cost_base_sum_tab  => g_cost_dummy_tab -- �_�~�[(�S��0)�̃f�[�^
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���׃f�[�^�擾
      OPEN get_cost_cur( g_base_tab(base_cnt).base_code );
      FETCH get_cost_cur BULK COLLECT INTO g_cost_line_tab;
      CLOSE get_cost_cur;
--
      -- �Ώۋ��_�ɖ��׃f�[�^������ꍇ�݈̂ȉ��̏���
      IF ( g_cost_line_tab.COUNT > 0 ) THEN
--
        -- =======================
        -- �w�b�_�o�͏���
        -- =======================
        put_head_data(
           ov_errbuf     => lv_errbuf
          ,ov_retcode    => lv_retcode
          ,ov_errmsg     => lv_errmsg
          ,iv_base_code  => g_base_tab(base_cnt).base_code
          ,iv_base_name  => g_base_tab(base_cnt).base_name
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        --���׃f�[�^���[�v
        <<line_loop>>
        FOR line_cnt IN 1 .. g_cost_line_tab.COUNT LOOP
--
          -- �i�ږ��̂̃`�F�b�N
          IF ( g_cost_line_tab(line_cnt).item_name IS NULL ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10183,
                       iv_token_name1  => cv_item_code,
                       iv_token_value1 => g_cost_line_tab(line_cnt).item_code
                     );
            lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                     );
            RAISE no_data_expt;
          END IF;
--
          -- �ŏ���1�s��
          IF ( lt_item_code IS NULL ) THEN
            -- �u���[�N���̕ێ��ϐ��ݒ�
            lt_item_code                   := g_cost_line_tab(line_cnt).item_code;
            lt_item_name                   := g_cost_line_tab(line_cnt).item_name;
            ln_item_cnt                    := 1;
            l_cost_l_item_tab(ln_item_cnt) := g_cost_line_tab(line_cnt);
          -- �i�ڃu���[�N(1�i�ڂɂ�����(�ԗ�)�A����(����)�A�\�Z�̍ő�3���R�[�h�ƂȂ�)
          ELSIF ( g_cost_line_tab(line_cnt).item_code <> lt_item_code ) THEN
            -- =======================
            -- ���׃f�[�^�ҏW(�i�ږ�)
            -- =======================
            edit_line_data(
               ov_errbuf     => lv_errbuf
              ,ov_retcode    => lv_retcode
              ,ov_errmsg     => lv_errmsg
              ,iv_item_code  => lt_item_code
              ,iv_item_name  => lt_item_name
              ,i_cost_tab    => l_cost_l_item_tab
            );
            -- �G���[����
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            -- �i�ڒP�ʃe�[�u���̏�����
            l_cost_l_item_tab.DELETE;
            -- �u���[�N���̕ێ�
            lt_item_code                   := g_cost_line_tab(line_cnt).item_code;
            lt_item_name                   := g_cost_line_tab(line_cnt).item_name;
            ln_item_cnt                    := 1;
            l_cost_l_item_tab(ln_item_cnt) := g_cost_line_tab(line_cnt);
          -- ����i�ڂ̃f�[�^
          ELSE
            -- �z��Ƀf�[�^��ێ�
            ln_item_cnt                    := ln_item_cnt + 1;
            l_cost_l_item_tab(ln_item_cnt) := g_cost_line_tab(line_cnt);
          END IF;
--
        END LOOP line_loop;
--
        -- =======================
        -- ���׃f�[�^�ҏW(�ŏI�s��)
        -- =======================
        edit_line_data(
           ov_errbuf     => lv_errbuf
          ,ov_retcode    => lv_retcode
          ,ov_errmsg     => lv_errmsg
          ,iv_item_code  => lt_item_code
          ,iv_item_name  => lt_item_name
          ,i_cost_tab    => l_cost_l_item_tab
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =======================
        -- ���_�v�f�[�^�o�͏���
        -- =======================
        put_base_sum_data(
            ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP base_loop;
--
  EXCEPTION
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y
      IF ( get_cost_cur%ISOPEN ) THEN
        CLOSE get_cost_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_line_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : ���_���o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf           OUT     VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT     VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT     VARCHAR2,   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    o_base_tab          OUT     base_ttype) -- ���_���
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_base_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ln_base_index     NUMBER       DEFAULT 1;    -- ���_���p�C���f�b�N�X
    lv_resp_nm        VARCHAR2(40) DEFAULT NULL; -- �E�Ӗ�
    ln_admin_resp_id  NUMBER       DEFAULT NULL; -- ��Ǖ����S����
    ln_main_resp_id   NUMBER       DEFAULT NULL; -- �{������S����
    ln_sales_resp_id  NUMBER       DEFAULT NULL; -- ���_����S����
    lv_belong_base_cd VARCHAR2(4)  DEFAULT NULL; -- �������_
    lb_retcode        BOOLEAN      DEFAULT TRUE; -- ���b�Z�[�W�o�͊֐��߂�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���_���J�[�\��
    CURSOR base_name_cur(
      iv_base_code IN VARCHAR2) -- ���_�R�[�h
    IS
      SELECT account_name AS base_name
      FROM   hz_cust_accounts
      WHERE  account_number      = iv_base_code
      AND    customer_class_code = cv_cust_cd_base -- ���_
    ;
    -- ���_���J�[�\�����R�[�h�^
    base_name_rec base_name_cur%ROWTYPE;
    -- �S���_�J�[�\��
    CURSOR all_base_cur
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- ���_�R�[�h
              hca.account_name            AS base_name  -- ���_��
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl            ffvv,
              hz_cust_accounts              hca
      WHERE   ffvnh.parent_flex_value IN
          (SELECT  ffvnh.child_flex_value_high
           FROM    fnd_flex_value_norm_hierarchy ffvnh,
                   fnd_flex_values_vl            ffvv
           WHERE   ffvnh.parent_flex_value IN
              (SELECT  ffvnh.child_flex_value_high
               FROM    fnd_flex_value_norm_hierarchy ffvnh,
                       fnd_flex_values_vl            ffvv
               WHERE   ffvnh.parent_flex_value IN
                  (SELECT ffvnh.child_flex_value_high
                   FROM   fnd_flex_value_norm_hierarchy ffvnh,
                          fnd_flex_values_vl            ffvv
                   WHERE  ffvnh.parent_flex_value IN
                      (SELECT  ffvnh.child_flex_value_high
                       FROM    fnd_flex_value_norm_hierarchy ffvnh,
                               fnd_flex_values_vl            ffvv
                       WHERE   ffvnh.parent_flex_value     = gv_head_office_code -- �{�Е���R�[�h
                       AND     ffvv.value_category         = cv_flex_st_name_dept
                       AND     ffvnh.child_flex_value_high = ffvv.flex_value
                      )
                   AND    ffvv.value_category         = cv_flex_st_name_dept
                   AND    ffvnh.child_flex_value_high = ffvv.flex_value
                  )
               AND     ffvv.value_category         = cv_flex_st_name_dept
               AND     ffvnh.child_flex_value_high = ffvv.flex_value
              )
           AND     ffvv.value_category         = cv_flex_st_name_dept
           AND     ffvnh.child_flex_value_high = ffvv.flex_value
          )
      AND     ffvv.value_category         = cv_flex_st_name_dept
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- ���_
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- �S���_�J�[�\�����R�[�h�^
    all_base_rec all_base_cur%ROWTYPE;
    -- �z�����_�J�[�\��
    CURSOR child_base_cur(
      iv_base_code IN VARCHAR2) -- ���_�R�[�h
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- ���_�R�[�h
              hca.account_name            AS base_name  -- ���_��
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                         FROM   fnd_flex_value_sets ffvs,
                                                fnd_flex_value_norm_hierarchy ffvnh
                                         WHERE  ffvs.flex_value_set_name    = cv_flex_st_name_dept
                                         AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                         AND    ffvnh.child_flex_value_high = iv_base_code -- �������_�R�[�h
                                        )
      AND     ffvv.value_category         = cv_flex_st_name_dept
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- ���_
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- �z�����_�J�[�\�����R�[�h�^
    child_base_rec child_base_cur%ROWTYPE;
--
    -- *** ���[�J���E��O ***
    no_resp_id_expt   EXCEPTION;
    no_resp_data_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���_���̎擾
    -- ===============================
    -- ���̓p�����[�^�̋��_�����擾
    IF (gv_base_code IS NOT NULL) THEN
      <<base_name_loop>>
      FOR base_name_rec IN base_name_cur( gv_base_code ) LOOP
        o_base_tab(ln_base_index).base_code := gv_base_code;            -- ���_�R�[�h
        o_base_tab(ln_base_index).base_name := base_name_rec.base_name; -- ���_��
      END LOOP base_name_loop;
      -- ���_��񂪎擾�ł��Ȃ������ꍇ
      IF ( o_base_tab(1).base_name IS NULL ) THEN
        -- �G���[����
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10182,
                       iv_token_name1  => cv_resp_name,
                       iv_token_value1 => cv_resp_name_val,
                       iv_token_name2  => cv_location_code,
                       iv_token_value2 => gv_base_code
                     );
        lv_errbuf := lv_errmsg;
--
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_resp_data_expt;
      END IF;
    -- �E�ӕʂɋ��_���擾
    ELSE
      -- ===============================
      -- �E�ӕʂ̋��_�擾����
      -- ===============================
      ----------------------------
      -- ��Ǖ����S���ҐE�ӂ̏ꍇ
      ----------------------------
      IF ( gv_resp_type = cv_resp_type_0 ) THEN
        -- �S���_�R�[�h�Ƌ��_�����擾
        <<all_base_loop>>
        FOR all_base_rec IN all_base_cur LOOP
          o_base_tab(ln_base_index).base_code := all_base_rec.base_code; -- ���_�R�[�h
          o_base_tab(ln_base_index).base_name := all_base_rec.base_name; -- ���_��
          ln_base_index := ln_base_index + 1;
        END LOOP all_base_loop;
      ----------------------------
      -- �{������S���ҐE�ӂ̏ꍇ
      ----------------------------
      ELSE
        -- �������_�擾
        lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( gd_process_date, cn_created_by );
        IF ( lv_belong_base_cd IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_00012,
                         iv_token_name1  => cv_user_id,
                         iv_token_value1 => cn_created_by
                       );
--
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.LOG
                          , iv_message  => lv_errmsg
                          , in_new_line => cn_number_0
                          );
            RAISE no_resp_data_expt;
        END IF;
--
        IF ( gv_resp_type = cv_resp_type_1 ) THEN
          -- ���O�C�����[�U�[�̎����_���z���̋��_���擾
          <<child_base_loop>>
          FOR child_base_rec IN child_base_cur( lv_belong_base_cd ) LOOP
            o_base_tab(ln_base_index).base_code := child_base_rec.base_code; -- ���_�R�[�h
            o_base_tab(ln_base_index).base_name := child_base_rec.base_name; -- ���_��
            ln_base_index := ln_base_index + 1;
          END LOOP child_base_loop;
        ----------------------------
        -- ���_����_�S���ҐE�ӂ̏ꍇ
        ----------------------------
        ELSE
          -- �����_���擾
          o_base_tab(ln_base_index).base_code   := lv_belong_base_cd;        -- ���_�R�[�h
          <<resp_loop>>
          FOR base_name_rec IN base_name_cur( lv_belong_base_cd ) LOOP
            o_base_tab(ln_base_index).base_name := base_name_rec.base_name;  -- ���_��
          END LOOP resp_loop;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    --*** �E��ID�擾�G���[ ***
    WHEN no_resp_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_00052,
                      iv_token_name1  => cv_resp_name,
                      iv_token_value1 => lv_resp_nm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���_�擾��O ***
    WHEN no_resp_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- �\�Z�N�x
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- �E�Ӄ^�C�v
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(4) := 'init'; -- �v���O������
--
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_profile_nm   VARCHAR2(30) DEFAULT NULL; -- �v���t�@�C�����̂̊i�[�p
    lb_retcode      BOOLEAN;
--
    -- *** ���[�J���E��O ***
    no_profile_expt EXCEPTION; -- �v���t�@�C���l�擾�G���[
    no_org_id_expt  EXCEPTION; -- �݌ɑg�DID�擾�G���[
    no_process_date EXCEPTION; -- �Ɩ����t�擾�G���[
    no_data_expt    EXCEPTION; -- �f�[�^�擾�G���[
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- ���̓p�����[�^�̑ޔ�
    -- ===============================
    gv_base_code   := iv_base_code;   -- ���_�R�[�h
    gv_budget_year := iv_budget_year; -- �\�Z�N�x
    gv_resp_type   := iv_resp_type;   -- �E�Ӄ^�C�v
--
    -- ===============================
    -- ���̓p�����[�^�̏o��
    -- ===============================
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(1:���_�R�[�h)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00018,
                    iv_token_name1  => cv_location_code,
                    iv_token_value1 => gv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(2:�\�Z�N�x)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00019,
                    iv_token_name1  => cv_year,
                    iv_token_value1 => gv_budget_year
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_1     -- ���s��
                  );
    -- ===============================
    -- �v���t�@�C���l�擾
    -- ===============================
    -- �J�X�^���E�v���t�@�C���̍݌ɑg�D�R�[�h���擾���܂��B
    gv_org_code := fnd_profile.value(cv_pro_organization_code);
    IF ( gv_org_code IS NULL ) THEN
      lv_profile_nm := cv_pro_organization_code;
      RAISE no_profile_expt;
    END IF;
    -- �J�X�^���E�v���t�@�C���̖{�Ђ̕���R�[�h���擾���܂��B
    gv_head_office_code := fnd_profile.value(cv_pro_head_office_code);
    IF ( gv_head_office_code IS NULL ) THEN
      lv_profile_nm := cv_pro_head_office_code;
      RAISE no_profile_expt;
    END IF;
    -- �J�X�^���E�v���t�@�C���̐���Q�R�[�h���擾���܂��B
    gv_policy_group_code := fnd_profile.value(cv_pro_policy_group_code);
    IF ( gv_policy_group_code IS NULL ) THEN
      lv_profile_nm := cv_pro_policy_group_code;
      RAISE no_profile_expt;
    END IF;
    -- ===============================
    -- �݌ɑg�DID�̎擾
    -- ===============================
    gn_org_id := xxcoi_common_pkg.get_organization_id(gv_org_code);
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00013
                    , iv_token_name1  => cv_org_code
                    , iv_token_value1 => gv_org_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_org_id_expt;
    END IF;
    -- ===============================
    -- ���O�C�����̏��擾
    -- ===============================
    gn_resp_id := fnd_global.resp_id; -- �E��ID
    gn_user_id := fnd_global.user_id; -- ���[�U�[ID
    -- =============================================
    -- �Ɩ��������t�擾
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_process_date;
    END IF;
    -- =============================================
    -- ���ڌ��o���̎擾
    -- =============================================
    OPEN  put_value_cur;
    FETCH put_value_cur BULK COLLECT INTO g_put_value_tab;
    CLOSE put_value_cur;
    -- �Ώی����`�F�b�N
    IF ( g_put_value_tab.COUNT <> cn_heading_cnt ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00015,
                     iv_token_name1  => cv_token_lookup_value_set,
                     iv_token_value1 => cv_lookup_type_put_val
                   );
      RAISE no_data_expt;
    END IF;
    -- =============================================
    -- �������̎擾
    -- =============================================
    BEGIN
      SELECT flv.attribute12
      INTO   gv_month_f
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type           = cv_lookup_type_month_c
      AND    flv.lookup_code           = cv_lookup_code_month_c
      AND    flv.enabled_flag          = cv_flag_y
      AND    flv.language              = cv_lang
      AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- �K�p�J�n��
      AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- �K�p�I����
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_00015,
                       iv_token_name1  => cv_token_lookup_value_set,
                       iv_token_value1 => cv_lookup_type_month_c
                     );
        RAISE no_data_expt;
    END;
    --NULL�`�F�b�N
    IF ( gv_month_f IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00015,
                     iv_token_name1  => cv_token_lookup_value_set,
                     iv_token_value1 => cv_lookup_type_month_c
                   );
      RAISE no_data_expt;
    END IF;
    -- =============================================
    -- �_�~�[�s(���z�E���ʑS��0)�̕ҏW
    -- =============================================
    g_cost_dummy_tab(1).qty_month1     := 0;
    g_cost_dummy_tab(1).amt_month1     := 0;
    g_cost_dummy_tab(1).qty_month2     := 0;
    g_cost_dummy_tab(1).amt_month2     := 0;
    g_cost_dummy_tab(1).qty_month3     := 0;
    g_cost_dummy_tab(1).amt_month3     := 0;
    g_cost_dummy_tab(1).qty_month4     := 0;
    g_cost_dummy_tab(1).amt_month4     := 0;
    g_cost_dummy_tab(1).qty_month5     := 0;
    g_cost_dummy_tab(1).amt_month5     := 0;
    g_cost_dummy_tab(1).qty_month6     := 0;
    g_cost_dummy_tab(1).amt_month6     := 0;
    g_cost_dummy_tab(1).qty_first_half := 0;
    g_cost_dummy_tab(1).amt_first_half := 0;
    g_cost_dummy_tab(1).qty_month7     := 0;
    g_cost_dummy_tab(1).amt_month7     := 0;
    g_cost_dummy_tab(1).qty_month8     := 0;
    g_cost_dummy_tab(1).amt_month8     := 0;
    g_cost_dummy_tab(1).qty_month9     := 0;
    g_cost_dummy_tab(1).amt_month9     := 0;
    g_cost_dummy_tab(1).qty_month10    := 0;
    g_cost_dummy_tab(1).amt_month10    := 0;
    g_cost_dummy_tab(1).qty_month11    := 0;
    g_cost_dummy_tab(1).amt_month11    := 0;
    g_cost_dummy_tab(1).qty_month12    := 0;
    g_cost_dummy_tab(1).amt_month12    := 0;
    g_cost_dummy_tab(1).qty_year_sum   := 0;
    g_cost_dummy_tab(1).amt_year_sum   := 0;
--
  EXCEPTION
    --*** �v���t�@�C���l�擾�G���[ ***
    WHEN no_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00003,
                     iv_token_name1  => cv_profile,
                     iv_token_value1 => lv_profile_nm
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �݌ɑg�DID�擾�G���[ ***
    WHEN no_org_id_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �Ɩ����t�擾�擾�G���[ ***
    WHEN no_process_date THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h��
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�J�[�\����OPEN�̏ꍇ��CLOSE
      IF ( put_value_cur%ISOPEN ) THEN
        CLOSE put_value_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- �\�Z�N�x
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- �E�Ӄ^�C�v
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      ov_errbuf      => lv_errbuf,      -- �G���[�E���b�Z�[�W
      ov_retcode     => lv_retcode,     -- ���^�[���E�R�[�h
      ov_errmsg      => lv_errmsg,      -- ���[�U�[�E�G���[�E���b�Z�[�W
      iv_base_code   => iv_base_code,   -- ���_�R�[�h
      iv_budget_year => iv_budget_year, -- �\�Z�N�x
      iv_resp_type   => iv_resp_type    -- �E�Ӄ^�C�v
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- ���_�f�[�^�̎擾(A-2)
    -- ===============================
    get_base_data(
      ov_errbuf      => lv_errbuf,     -- �G���[�E���b�Z�[�W
      ov_retcode     => lv_retcode,    -- ���^�[���E�R�[�h
      ov_errmsg      => lv_errmsg,     -- ���[�U�[�E�G���[�E���b�Z�[�W
      o_base_tab     => g_base_tab     -- ���_���
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- ���׃f�[�^�擾����(A-3)
    -- ===============================
    get_line_data(
      lv_errbuf,  -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode, -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf         OUT VARCHAR2, -- �G���[�E���b�Z�[�W --# �Œ� #
    retcode        OUT VARCHAR2, -- ���^�[���E�R�[�h   --# �Œ� #
    iv_base_code   IN  VARCHAR2, -- 1.���_�R�[�h
    iv_budget_year IN  VARCHAR2, -- 2.�\�Z�N�x
    iv_resp_type   IN  VARCHAR2  -- 3.�E�Ӄ^�C�v
  )
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(16)   DEFAULT NULL; -- ���b�Z�[�W�R�[�h
    lb_retcode      BOOLEAN;
--
  BEGIN
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => 'LOG'-- ���O�o��
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- submain�̌Ăяo��
    -- ===============================
    submain(
      ov_errbuf      => lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode     => lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg      => lv_errmsg,      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_base_code   => iv_base_code,   -- ���_�R�[�h
      iv_budget_year => iv_budget_year, -- �\�Z�N�x
      iv_resp_type   => iv_resp_type    -- �E�Ӄ^�C�v
    );
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line => cn_number_0    -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errbuf      -- ���b�Z�[�W
                    , in_new_line => cn_number_1    -- ���s
                    );
      -- �Ώی����E���������E�G���[�����̐ݒ�
      gn_error_cnt  := 1;
    END IF;
    -- ���׏o�͌�����0���̏ꍇ
    IF ( gn_put_count = 0 ) AND ( lv_retcode = cv_status_normal ) THEN
      -- �Ώۃf�[�^�����̃��b�Z�[�W�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_10184,
                      iv_token_name1  => cv_year,
                      iv_token_value1 => gv_budget_year
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.LOG,   -- LOG
                     iv_message  => gv_out_msg,     -- ���b�Z�[�W
                     in_new_line => cn_number_1     -- ���s��
                    );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90000,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90001,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90002,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_1     -- ���s��
                  );
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal )   THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn )  THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK023A03C;
/
