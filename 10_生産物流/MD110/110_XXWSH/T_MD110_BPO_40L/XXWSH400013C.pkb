CREATE OR REPLACE PACKAGE BODY APPS.XXWSH400013C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXWSH400013C(body)
 * Description      : �o�׈˗��X�V�A�b�v���[�h
 * MD.050           : �o�׈˗� <MD050_BPO_401>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(M-1)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾(M-2)
 *  get_ship_request_data  �o�׈˗��f�[�^�擾(M-3)
 *  upd_order_data         �󒍃A�h�I���X�V(M-4)
 *  del_data               �f�[�^�폜(M-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/01/23    1.0   K.Kiriu          �V�K�쐬(E_�{�ғ�_14672)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
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
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_lock_expt     EXCEPTION;               -- ���b�N�G���[��O*
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXWSH400013C';     -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxwsh       CONSTANT VARCHAR2(5)   := 'XXWSH';            -- XXWSH
  cv_appl_name_xxcmn       CONSTANT VARCHAR2(5)   := 'XXCMN';            -- XXCMN
  -- ���b�Z�[�W(XXWSH)
  cv_msg_xxwsh_13192       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13192';  -- �p�����[�^�����̓G���[
  cv_msg_xxwsh_13193       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13193';  -- �v���t�@�C���擾���s�G���[
  cv_msg_xxwsh_13194       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13194';  -- �݌ɑg�DID�擾���s�G���[
  cv_msg_xxwsh_13195       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13195';  -- �f�[�^�擾�G���[
  cv_msg_xxwsh_13196       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13196';  -- ���b�N�擾�G���[
  cv_msg_xxwsh_13197       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13197';  -- �Q�ƃ^�C�v�擾�G���[
  cv_msg_xxwsh_13228       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13228';  -- �p�����[�^�o��
  cv_msg_xxwsh_13198       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13198';  -- �}���G���[
  cv_msg_xxwsh_13223       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13223';  -- �폜�G���[
  cv_msg_xxwsh_13199       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13199';  -- �Ώۖ����݃G���[
  cv_msg_xxwsh_13238       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13238';  -- �݌ɉ�v���ԃ`�F�b�N�G���[
  cv_msg_xxwsh_13200       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13200';  -- ����^�C�v�G���[
  cv_msg_xxwsh_13201       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13201';  -- �X�e�[�^�X�G���[
  cv_msg_xxwsh_13202       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13202';  -- �ʒm�X�e�[�^�X�G���[
  cv_msg_xxwsh_13203       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13203';  -- �d�ʗe�ϋ敪�G���[
  cv_msg_xxwsh_13204       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13204';  -- �蓮�����ς݃G���[
  cv_msg_xxwsh_13205       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13205';  -- �X�V���ڂȂ��G���[
  cv_msg_xxwsh_13206       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13206';  -- �ΏۊO�i�ڃG���[�i�ύX�O�j
  cv_msg_xxwsh_13207       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13207';  -- �ΏۊO�i�ڃG���[�i�ύX��j
  cv_msg_xxwsh_13208       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13208';  -- �K�{�G���[
  cv_msg_xxwsh_13209       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13209';  -- INV�i�ڑΏۊO�G���[
  cv_msg_xxwsh_13210       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13210';  -- �q�i�ڑΏۊO�G���[
  cv_msg_xxwsh_13211       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13211';  -- �o�ד��������{�G���[
  cv_msg_xxwsh_13212       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13212';  -- �����I�[�o�[�G���[
  cv_msg_xxwsh_13213       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13213';  -- ���ʊ֐��G���[�i�ύڌ����`�F�b�N(���v�l�Z�o)�j
  cv_msg_xxwsh_13231       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13231';  -- �����\���A�h�I�����o�^���[�j���O
  cv_msg_xxwsh_13248       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13248';  -- �o�׉ۃ`�F�b�N�֐��G���[���[�j���O
  cv_msg_xxwsh_13232       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13232';  -- �o�׉ۃ`�F�b�N�i�o�א������j���[�j���O
  cv_msg_xxwsh_13235       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13235';  -- �o�׉ۃ`�F�b�N�i�o�ג�~���j���[�j���O
  cv_msg_xxwsh_13236       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13236';  -- �o�׉ۃ`�F�b�N�i����v��j���[�j���O
  cv_msg_xxwsh_13214       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13214';  -- ���b�N�擾�G���[�Q
  cv_msg_xxwsh_13215       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13215';  -- �X�V�G���[
  cv_msg_xxwsh_13216       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13216';  -- ���ʊ֐��G���[�i���������j
  cv_msg_xxwsh_13217       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13217';  -- ���ʊ֐��G���[�i�ő�z���敪�Z�o�j
  cv_msg_xxwsh_13239       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13239';  -- �p���b�g�ő喇�����߃��[�j���O
  cv_msg_xxwsh_13218       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13218';  -- ���ʊ֐��G���[(�ύڌ����`�F�b�N(�ύڌ����Z�o))
  cv_msg_xxwsh_13219       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13219';  -- �ύڏd�ʃI�[�o�[�G���[
  cv_msg_xxwsh_13220       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13220';  -- ���b�N�擾�G���[�R
  cv_msg_xxwsh_13221       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13221';  -- �X�V�G���[�Q
  cv_msg_xxwsh_13222       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13222';  -- ���ʊ֐��G���[�i�z�ԉ����֐��j
  cv_msg_xxwsh_13240       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13240';  -- ���ڌ�No�擾���s�G���[
  cv_msg_xxwsh_13241       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13241';  -- ���ڍ��v�d�ʃI�[�o�[�G���[
  cv_msg_xxwsh_13251       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13251';  -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxwsh_13252       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13252';  -- �f�[�^���ڐ��}�C�i�X�G���[����
  -- ���b�Z�[�W(XXCMN)
  cv_msg_xxcmn_10640       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10640';  -- BLOB�f�[�^�ϊ��G���[
  cv_msg_xxcmn_10639       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10639';  -- �t�@�C�����ڃ`�F�b�N�G���[
  -- �g�[�N�����b�Z�[�W
  cv_msg_xxwsh_13224       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13224';  -- �t�@�C��ID(����)
  cv_msg_xxwsh_13225       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13225';  -- �t�H�[�}�b�g�p�^�[��(����)
  cv_msg_xxwsh_13226       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13226';  -- �t�@�C���A�b�v���[�hIF�e�[�u��(����)
  cv_msg_xxwsh_13227       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13227';  -- �o�׈˗��X�V�A�b�v���[�h���ڒ�`(����)
  cv_msg_xxwsh_13229       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13229';  -- �o�׈˗��X�V�A�b�v���[�h(����)
  cv_msg_xxwsh_13230       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13230';  -- �o�׈˗��X�V�A�b�v���[�h���[�N(����)
  cv_msg_xxwsh_13244       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13244';  -- ���o�Ɋ��Z�P��(����)
  cv_msg_xxwsh_13245       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13245';  -- �P�[�X��(����)
  cv_msg_xxwsh_13246       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13246';  -- �p���b�g�l�ő�i��(����)
  cv_msg_xxwsh_13247       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13247';  -- �z��(����)
  cv_msg_xxwsh_13233       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13233';  -- �o�א�����(���i��)(����)
  cv_msg_xxwsh_13234       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13234';  -- �o�א�����(������)(����)
  cv_msg_xxwsh_13237       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13237';  -- �o�א�����(����v�揤�i)(����)
  cv_msg_xxwsh_13249       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13249';  -- �󒍖��׃A�h�I��(����)
  cv_msg_xxwsh_13250       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13250';  -- �󒍃w�b�_�A�h�I��(����)
  -- �f�[�^�擾�p���b�Z�[�W
  cv_msg_xxwsh_13242       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13242';  -- �i�ڋ敪�i�����j
  cv_msg_xxwsh_13243       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13243';  -- ���i�敪�i�����j
  -- �g�[�N��
  cv_tkn_parameter         CONSTANT VARCHAR2(9)   := 'PARAMETER';
  cv_tkn_prof_name         CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_tkn_org_code          CONSTANT VARCHAR2(8)   := 'ORG_CODE';
  cv_tkn_table             CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_tkn_lookup            CONSTANT VARCHAR2(6)   := 'LOOKUP';
  cv_tkn_upload_name       CONSTANT VARCHAR2(11)  := 'UPLOAD_NAME';
  cv_tkn_file_name         CONSTANT VARCHAR2(9)   := 'FILE_NAME';
  cv_tkn_file_id           CONSTANT VARCHAR2(7)   := 'FILE_ID';
  cv_tkn_format            CONSTANT VARCHAR2(6)   := 'FORMAT';
  cv_tkn_count             CONSTANT VARCHAR2(5)   := 'COUNT';
  cv_tkn_input_line_no     CONSTANT VARCHAR2(13)  := 'INPUT_LINE_NO';
  cv_tkn_err_msg           CONSTANT VARCHAR2(7)   := 'ERR_MSG';
  cv_tkn_request_no        CONSTANT VARCHAR2(10)  := 'REQUEST_NO';
  cv_tkn_item_code         CONSTANT VARCHAR2(9)   := 'ITEM_CODE';
  cv_tkn_ship_date         CONSTANT VARCHAR2(9)   := 'SHIP_DATE';
  cv_tkn_pallet_q          CONSTANT VARCHAR2(15)  := 'PALLET_QUANTITY';
  cv_tkn_layer_q           CONSTANT VARCHAR2(14)  := 'LAYER_QUANTITY';
  cv_tkn_case_q            CONSTANT VARCHAR2(13)  := 'CASE_QUANTITY';
  cv_tkn_column            CONSTANT VARCHAR2(6)   := 'COLUMN';
  cv_tkn_quantity          CONSTANT VARCHAR2(8)   := 'QUANTITY';
  cv_tkn_num_of_deliver    CONSTANT VARCHAR2(14)  := 'NUM_OF_DELIVER';
  cv_tkn_deliver_to        CONSTANT VARCHAR2(10)  := 'DELIVER_TO';
  cv_tkn_deliver_from      CONSTANT VARCHAR2(12)  := 'DELIVER_FROM';
  cv_tkn_hs_branch         CONSTANT VARCHAR2(9)   := 'HS_BRANCH';
  cv_tkn_chk_type          CONSTANT VARCHAR2(9)   := 'CHK_TYPE';
  cv_tkn_base_date         CONSTANT VARCHAR2(9)   := 'BASE_DATE';
  cv_tkn_prod_class        CONSTANT VARCHAR2(10)  := 'PROD_CLASS';
  cv_tkn_weight_class      CONSTANT VARCHAR2(12)  := 'WEIGHT_CLASS';
  cv_tkn_err_code          CONSTANT VARCHAR2(10)  := 'ERROR_CODE';
  cv_tkn_s_method_code     CONSTANT VARCHAR2(16)  := 'SHIP_METHOD_CODE';
  cv_tkn_weight            CONSTANT VARCHAR2(6)   := 'WEIGHT';
  cv_max_weight            CONSTANT VARCHAR2(10)  := 'MAX_WEIGHT';
  cv_cur_weight            CONSTANT VARCHAR2(10)  := 'CUR_WEIGHT';
  -- �v���t�@�C��
  cv_prf_item_num          CONSTANT VARCHAR2(27)  := 'XXWSH_ORDER_UPLOAD_ITEM_NUM';    -- XXWSH:�o�׈˗��X�V���ڐ�
  cv_prf_org_code          CONSTANT VARCHAR2(18)  := 'XXWSH_INV_ORG_CODE';             -- XXWSH:INV�݌ɑg�D�R�[�h
  -- �Q�ƃ^�C�v�R�[�h
  cv_lookup_upload_def     CONSTANT VARCHAR2(22)  := 'XXWSH_ORDER_UPLOAD_DEF';         -- �o�׈˗��X�V�A�b�v���[�h���ڒ�`
  cv_lookup_process_upload CONSTANT VARCHAR2(22)  := 'XXWSH_PROCESS_UPLOAD';           -- ������ʁi�o�׈˗��X�V�A�b�v���[�h�j
  cv_lookup_t_status       CONSTANT VARCHAR2(24)  := 'XXWSH_TRANSACTION_STATUS';       -- �X�e�[�^�X
  cv_lookup_n_status       CONSTANT VARCHAR2(18)  := 'XXWSH_NOTIF_STATUS';             -- �ʒm�X�e�[�^�X
  -- ���ڒ�`
  cv_null_ok               CONSTANT VARCHAR2(7)   := 'NULL_OK';          -- �C�Ӎ���
  cv_null_ng               CONSTANT VARCHAR2(7)   := 'NULL_NG';          -- �K�{����
  cv_varchar               CONSTANT VARCHAR2(8)   := 'VARCHAR2';         -- ������
  cv_number                CONSTANT VARCHAR2(6)   := 'NUMBER';           -- ���l
  cv_date                  CONSTANT VARCHAR2(4)   := 'DATE';             -- ���t
  cv_varchar_cd            CONSTANT VARCHAR2(1)   := '0';                -- �����񍀖�
  cv_number_cd             CONSTANT VARCHAR2(1)   := '1';                -- ���l����
  cv_date_cd               CONSTANT VARCHAR2(1)   := '2';                -- ���t����
  cv_not_null              CONSTANT VARCHAR2(1)   := '1';                -- �K�{
  -- CSV�t�@�C���̃f�~���^����
  cv_msg_comma             CONSTANT VARCHAR2(1)   := ',';                -- �J���}
  -- �d�ʗe�ϋ敪
  cv_weight                CONSTANT VARCHAR2(1)   := '1';                -- �d��
  -- �����蓮�����敪
  cv_reserve_flag_auto     CONSTANT VARCHAR2(2)   := '10';               -- ��������
  cv_manual                CONSTANT VARCHAR2(2)   := '20';               -- �蓮����
  -- �o�׋敪
  cv_ship_class_1          CONSTANT VARCHAR2(1)   := '1';                -- �o�׉�
  -- �p�~�敪
  cv_obsolete_class_0      CONSTANT VARCHAR2(1)   := '0';                -- �p�~����Ă��Ȃ�
  -- ���敪
  cv_rate_class_0          CONSTANT VARCHAR2(1)   := '0';                -- �W������
  -- ����Ώۋ敪
  cv_sales_div_1           CONSTANT VARCHAR2(1)   := '1';                -- ����Ώ�
  -- �J�e�S���i�i�ڋ敪�j
  cv_item_div_5            CONSTANT VARCHAR2(1)   := '5';                -- ���i
  -- �J�e�S���i���i�敪�j
  cv_product_div_2         CONSTANT VARCHAR2(1)   := '2';                -- �h�����N
  -- �i�ڃX�e�[�^�X
  cv_inactive              CONSTANT VARCHAR2(8)   := 'Inactive';         -- Inactive
  -- �i�ڃR�[�h��1����
  cv_item_code_5           CONSTANT VARCHAR2(1)   := '5';                -- ����
  cv_item_code_6           CONSTANT VARCHAR2(1)   := '6';                -- ����
  -- �o�׉ۃ`�F�b�N(���ʊ֐�)
  cv_check_class_2         CONSTANT VARCHAR2(1)   := '2';                -- �o�א�����(���i��)
  cv_check_class_3         CONSTANT VARCHAR2(1)   := '3';                -- �o�א�����(������)
  cv_check_class_4         CONSTANT VARCHAR2(1)   := '4';                -- �o�א�����(����v�揤�i)
  cn_ret_normal            CONSTANT NUMBER        := 0;                  -- �������ʁF����
  cn_ret_num_over          CONSTANT NUMBER        := 1;                  -- �������ʁF���ʃI�[�o�[
  cn_ret_date_err          CONSTANT NUMBER        := 2;                  -- �������ʁF�o�ג�~���G���[
  cv_plan_item_flag        CONSTANT VARCHAR(1)    := '1';                -- �v�揤�i�t���O:1(�v�揤�i�Ώ�)
  -- �Ɩ����(���ʊ֐�)
  cv_ship                  CONSTANT VARCHAR(1)    := '1';                -- �Ɩ���ʁF�o��
  -- �����敪
  cv_amount_class_small    CONSTANT VARCHAR(1)    := '1';                -- �����敪�F����
  -- �^���敪
  cv_freight_charge_on     CONSTANT VARCHAR(1)    := '1';                -- �^���敪�FON
  -- �R�[�h�敪(���ʊ֐�)
  cv_code_class_4          CONSTANT VARCHAR(1)    := '4';                -- �R�[�h�敪�P�F4(�q��)
  cv_code_class_9          CONSTANT VARCHAR(1)    := '9';                -- �R�[�h�敪�Q�F9(�z����)
  -- �ύڃI�[�o�[�敪(���ʊ֐�)
  cv_loading_over          CONSTANT VARCHAR2(1)   := '1';                -- �ύڃI�[�o�[
  -- �z�ԉ���(���ʊ֐�)
  cv_cancel_flag_judge     CONSTANT VARCHAR2(1)   := '2';                -- �d�ʃI�[�o�[�̏ꍇ�̂ݔz�ԉ���
  -- �V�X�e�����t
  cd_sysdate               CONSTANT DATE          := TRUNC(SYSDATE);     -- �V�X�e�����t
  -- �ėp
  cv_no                    CONSTANT VARCHAR2(1)   := 'N';                -- No
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                -- Yes
  cn_0                     CONSTANT NUMBER        := 0;                  -- 0
  cn_1                     CONSTANT NUMBER        := 1;                  -- 1
  cv_minus                 CONSTANT VARCHAR2(1)   := '-';                -- �}�C�i�X
  -- ���t�t�H�[�}�b�g
  cv_yyyymm                CONSTANT VARCHAR2(6)   := 'YYYYMM';           -- YYYYMM�`��
  cv_yyyymmdd_sla          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';       -- YYYY/MM/DD�`��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڒ�`���R�[�h�^��`
  TYPE g_item_def_rtype IS RECORD(
     item_name             VARCHAR2(100)                               -- ���ږ�
    ,item_attribute        VARCHAR2(100)                               -- ���ڑ���
    ,item_essential        VARCHAR2(100)                               -- �K�{�t���O
    ,item_length           NUMBER                                      -- ���ڂ̒���(��������)
    ,decim                 NUMBER                                      -- ���ڂ̒���(�����_�ȉ�)
  );
  -- �o�׈˗��X�V�A�b�v���[�h���[�N���R�[�h�^��`
  TYPE g_upload_work_rtype IS RECORD(
     line_number       xxwsh_order_upload_work.line_number%TYPE
    ,request_no        xxwsh_order_upload_work.request_no%TYPE
    ,item_code         xxwsh_order_upload_work.item_code%TYPE
    ,conv_item_code    xxwsh_order_upload_work.conv_item_code%TYPE
    ,pallet_quantity   xxwsh_order_upload_work.pallet_quantity%TYPE
    ,layer_quantity    xxwsh_order_upload_work.layer_quantity%TYPE
    ,case_quantity     xxwsh_order_upload_work.case_quantity%TYPE
    ,request_id        xxwsh_order_upload_work.request_id%TYPE
  );
  -- �o�׈˗��f�[�^���R�[�h�^��`
  TYPE g_order_rtype IS RECORD(
     transaction_type_name     xxwsh_oe_transaction_types_v.transaction_type_name%TYPE
    ,status                    xxcmn_lookup_values2_v.attribute1%TYPE
    ,notif_status              xxcmn_lookup_values2_v.attribute1%TYPE
    ,order_header_id           xxwsh_order_headers_all.order_header_id%TYPE
    ,request_no                xxwsh_order_headers_all.request_no%TYPE
    ,weight_capacity_class     xxwsh_order_headers_all.weight_capacity_class%TYPE
    ,freight_charge_class      xxwsh_order_headers_all.freight_charge_class%TYPE
    ,schedule_ship_date        xxwsh_order_headers_all.schedule_ship_date%TYPE
    ,schedule_arrival_date     xxwsh_order_headers_all.schedule_arrival_date%TYPE
    ,based_weight              xxwsh_order_headers_all.based_weight%TYPE
    ,mixed_no                  xxwsh_order_headers_all.mixed_no%TYPE
    ,head_sales_branch         xxwsh_order_headers_all.head_sales_branch%TYPE
    ,deliver_to                xxwsh_order_headers_all.deliver_to%TYPE
    ,deliver_from              xxwsh_order_headers_all.deliver_from%TYPE
    ,deliver_from_id           xxwsh_order_headers_all.deliver_from_id%TYPE
    ,xola_rowid                rowid
    ,order_line_id             xxwsh_order_lines_all.order_line_id%TYPE
    ,automanual_reserve_class  xxwsh_order_lines_all.automanual_reserve_class%TYPE
    ,request_item_code         xxwsh_order_lines_all.request_item_code%TYPE
    ,pallet_quantity           xxwsh_order_lines_all.pallet_quantity%TYPE
    ,layer_quantity            xxwsh_order_lines_all.layer_quantity%TYPE
    ,case_quantity             xxwsh_order_lines_all.case_quantity%TYPE
    ,shipped_quantity          xxwsh_order_lines_all.shipped_quantity%TYPE
    ,based_request_quantity    xxwsh_order_lines_all.based_request_quantity%TYPE
  );
  -- �ύX��̕i�ڃf�[�^���R�[�h�^��`
  TYPE g_new_item_rtype IS RECORD(
     item_id              xxcmn_item_mst2_v.item_id%TYPE
    ,parent_item_id       xxcmn_item_mst2_v.parent_item_id%TYPE
    ,inventory_item_id    xxcmn_item_mst2_v.inventory_item_id%TYPE
    ,item_no              xxcmn_item_mst2_v.item_no%TYPE
    ,conv_unit            xxcmn_item_mst2_v.conv_unit%TYPE
    ,num_of_cases         xxcmn_item_mst2_v.num_of_cases%TYPE
    ,max_palette_steps    xxcmn_item_mst2_v.max_palette_steps%TYPE
    ,delivery_qty         xxcmn_item_mst2_v.delivery_qty%TYPE
    ,item_um              xxcmn_item_mst2_v.item_um%TYPE
    ,num_of_deliver       xxcmn_item_mst2_v.num_of_deliver%TYPE
  );
  -- �X�V�p���׃f�[�^���R�[�h�^��`
  TYPE g_ship_line_data_rtype IS RECORD(
     line_number                 xxwsh_order_upload_work.line_number%TYPE               -- �sNo
    ,automanual_reserve_class    xxwsh_order_lines_all.automanual_reserve_class%TYPE    -- �����蓮�����敪
    ,order_header_id             xxwsh_order_headers_all.order_header_id%TYPE           -- �󒍃w�b�_�A�h�I��ID
    ,request_no                  xxwsh_order_headers_all.request_no%TYPE                -- �˗�No
    ,mixed_no                    xxwsh_order_headers_all.mixed_no%TYPE                  -- ���ڌ�No
    ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE         -- �Ǌ����_
    ,deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE                -- �o�א�
    ,deliver_from                xxwsh_order_headers_all.deliver_from%TYPE              -- �o�׌��ۊǏꏊ
    ,deliver_from_id             xxwsh_order_headers_all.deliver_from_id%TYPE           -- �o�׌�ID
    ,schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE        -- �o�ɗ\���
    ,schedule_arrival_date       xxwsh_order_headers_all.schedule_arrival_date%TYPE     -- ���ח\���
    ,xola_rowid                  rowid                                                  -- ����ROWID
    ,order_line_id               xxwsh_order_lines_all.order_line_id%TYPE               -- �󒍖��׃A�h�I��ID
    ,shipping_inventory_item_id  xxwsh_order_lines_all.shipping_inventory_item_id%TYPE  -- �o�וi��ID
    ,shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE          -- �o�וi��
    ,quantity                    xxwsh_order_lines_all.quantity%TYPE                    -- ����
    ,uom_code                    xxwsh_order_lines_all.uom_code%TYPE                    -- �P��
    ,shipped_quantity            xxwsh_order_lines_all.shipped_quantity%TYPE            -- �o�׎��ѐ���
    ,based_request_quantity      xxwsh_order_lines_all.based_request_quantity%TYPE      -- ���_�˗�����
    ,request_item_id             xxwsh_order_lines_all.request_item_id%TYPE             -- �˗��i��ID
    ,request_item_code           xxwsh_order_lines_all.request_item_code%TYPE           -- �˗��i��
    ,po_number                   xxwsh_order_lines_all.po_number%TYPE                   -- ����NO
    ,pallet_quantity             xxwsh_order_lines_all.pallet_quantity%TYPE             -- �p���b�g��
    ,layer_quantity              xxwsh_order_lines_all.layer_quantity%TYPE              -- �i��
    ,case_quantity               xxwsh_order_lines_all.case_quantity%TYPE               -- �P�[�X��
    ,weight                      xxwsh_order_lines_all.weight%TYPE                      -- �d��
    ,capacity                    xxwsh_order_lines_all.capacity%TYPE                    -- �e��
    ,pallet_weight               xxwsh_order_lines_all.pallet_weight%TYPE               -- �p���b�g�d��
    ,pallet_qty                  xxwsh_order_lines_all.pallet_qty%TYPE                  -- �p���b�g����
    ,shipping_request_if_flg     xxwsh_order_lines_all.shipping_request_if_flg%TYPE     -- �o�׈˗��C���^�t�F�[�X�σt���O
    ,shipping_result_if_flg      xxwsh_order_lines_all.shipping_result_if_flg%TYPE      -- �o�׎��уC���^�t�F�[�X�σt���O
    ,last_updated_by             xxwsh_order_lines_all.last_updated_by%TYPE             -- �ŏI�X�V��
    ,last_update_date            xxwsh_order_lines_all.last_update_date%TYPE            -- �ŏI�X�V��
    ,last_update_login           xxwsh_order_lines_all.last_update_login%TYPE           -- �ŏI�X�V���O�C��
    ,request_id                  xxwsh_order_lines_all.request_id%TYPE                  -- �v��ID
    ,program_application_id      xxwsh_order_lines_all.program_application_id%TYPE      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ,program_id                  xxwsh_order_lines_all.program_id%TYPE                  -- �R���J�����g�E�v���O����ID
    ,program_update_date         xxwsh_order_lines_all.program_update_date%TYPE         -- �v���O�����X�V��
  );
  -- ���ڒ�`�e�[�u���^��`
  TYPE g_item_def_ttype       IS TABLE OF g_item_def_rtype       INDEX BY BINARY_INTEGER;
  -- �o�׈˗��X�V�A�b�v���[�h���[�N�e�[�u���^��`
  TYPE g_upload_work_ttype    IS TABLE OF g_upload_work_rtype    INDEX BY BINARY_INTEGER;
  -- �X�V�p���׃f�[�^�e�[�u���^��`
  TYPE g_ship_line_data_ttype IS TABLE OF g_ship_line_data_rtype INDEX BY BINARY_INTEGER;
  -- ���ڒ�`�e�[�u���^
  gt_item_def_tab        g_item_def_ttype;
  -- �o�׈˗��X�V�A�b�v���[�h���[�N�e�[�u���^
  gt_upload_work_tab     g_upload_work_ttype;
  -- �X�V�p���׃f�[�^�e�[�u���^
  gt_ship_line_data_tab  g_ship_line_data_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_id                       NUMBER;            -- �t�@�C���h�c
  gv_format                        VARCHAR2(100);     -- �t�H�[�}�b�g�p�^�[��
  gn_item_num                      NUMBER;            -- �o�׈˗��X�V���ڐ�
  gv_org_code                      VARCHAR2(100);     -- INV�݌ɑg�D�R�[�h
  gn_inv_org_id                    NUMBER;            -- INV�݌ɑg�DID
  gv_opm_close_period              VARCHAR2(6);       -- OPM�N���[�Y��v����
  gv_item_div_name                 VARCHAR2(20);      -- �J�e�S���Z�b�g���i�i�ڋ敪�j����
  gv_product_div_name              VARCHAR2(20);      -- �J�e�S���Z�b�g���i���i�敪�j����
  gn_skip_cnt                      NUMBER;            -- �X�L�b�v����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(M-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2  -- �t�@�C���h�c
    ,iv_format     IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J����`��O ***
    get_param_expt            EXCEPTION;                                       -- �p�����[�^NULL�G���[
    get_profile_expt          EXCEPTION;                                       -- �v���t�@�C���擾��O
    get_org_id_expt           EXCEPTION;                                       -- INV�݌ɑg�DID�擾�G���[
    get_data_expt             EXCEPTION;                                       -- �f�[�^�擾�G���[
    get_lookup_expt           EXCEPTION;                                       -- �Q�ƃ^�C�v�擾�G���[
    -- *** ���[�J���ϐ� ***
    lv_error_token            VARCHAR2(100);                                   -- �g�[�N�����b�Z�[�W�i�[�p
    ln_cnt                    NUMBER;                                          -- ���ڒ�`�m�F�p
    lv_parameter              VARCHAR2(5000);                                  -- �p�����[�^�o�͗p
    lv_csv_file_name          xxinv_mrp_file_ul_interface.file_name%TYPE;      -- �t�@�C�����i�[�p
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���ڒ�`�擾�p�J�[�\��
    CURSOR get_def_info_cur
    IS
      SELECT   xlvv.meaning                     AS item_name       -- ���e
              ,DECODE( xlvv.attribute1
                      ,cv_varchar, cv_varchar_cd
                      ,cv_number , cv_number_cd
                      , cv_date_cd
                     )                          AS item_attribute  -- ���ڑ���
              ,DECODE( xlvv.attribute2
                      ,cv_not_null, cv_null_ng
                      ,cv_null_ok
                     )                          AS item_essential  -- �K�{�t���O
              ,TO_NUMBER(xlvv.attribute3)       AS item_length     -- ����(����)
              ,TO_NUMBER(xlvv.attribute4)       AS decim           -- ����(�����_�ȉ�)
      FROM     xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�hVIEW
      WHERE    xlvv.lookup_type        = cv_lookup_upload_def
      ORDER BY xlvv.lookup_code
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- M-1.1 ���̓p�����[�^�iFILE_ID�A�t�H�[�}�b�g�j��NULL�`�F�b�N
    --==============================================================
--
    -- 1.�t�@�C��ID
    IF ( iv_file_id IS NULL ) THEN
      lv_error_token := cv_msg_xxwsh_13224;
      RAISE get_param_expt;
    END IF;
--
    -- 2.�t�H�[�}�b�g�p�^�[��
    IF ( iv_format IS NULL ) THEN
      lv_error_token := cv_msg_xxwsh_13225;
      RAISE get_param_expt;
    END IF;
--
    -- IN�p�����[�^���i�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
--
    --==============================================================
    -- M-1.2 �v���t�@�C���l�擾
    --==============================================================
--
    -- XXWSH:�o�׈˗��X�V���ڐ��̎擾
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num));
    -- �擾�G���[��
    IF ( gn_item_num IS NULL ) THEN
      lv_error_token := cv_prf_item_num;
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:INV�݌ɑg�D�R�[�h�̎擾
    gv_org_code := FND_PROFILE.VALUE(cv_prf_org_code);
    -- �擾�G���[��
    IF ( gv_org_code IS NULL ) THEN
      lv_error_token := cv_prf_org_code;
      RAISE get_profile_expt;
    END IF;
--
    --==============================================================
    -- M-1.3 INV�݌ɑg�DID�擾
    --==============================================================
    BEGIN
      SELECT  mp.organization_id  master_org_id   -- INV�݌ɑg�DID
      INTO    gn_inv_org_id
      FROM    mtl_parameters  mp  -- �g�D�p�����[�^
      WHERE   mp.organization_code = gv_org_code  -- ��L�Ŏ擾����INV�݌ɑg�D�R�[�h
      ;
    --
    EXCEPTION
      -- �擾�G���[��
      WHEN NO_DATA_FOUND THEN
        lv_error_token := gv_org_code;
        RAISE get_org_id_expt;
    END;
--
    --==============================================================
    -- M-1.4 �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    BEGIN
      SELECT  fui.file_name      file_name     -- �t�@�C����
      INTO    lv_csv_file_name
      FROM    xxinv_mrp_file_ul_interface  fui -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE   fui.file_id = gn_file_id         -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    --
    EXCEPTION
      -- �擾�G���[��
      WHEN NO_DATA_FOUND THEN
        lv_error_token := cv_msg_xxwsh_13226;
        RAISE get_data_expt;
      -- ���b�N�擾�G���[��
      WHEN global_lock_expt THEN
        lv_error_token := cv_msg_xxwsh_13226;
        RAISE global_lock_expt;
    END;
--
    --==============================================================
    -- M-1.5 �o�׈˗��X�V�A�b�v���[�h���ڒ�`���̎擾
    --==============================================================
    -- �ϐ��̏�����
    ln_cnt := 0;
    -- �e�[�u����`�擾LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_item_def_tab(ln_cnt).item_name       := get_def_info_rec.item_name;       -- ���ږ�
      gt_item_def_tab(ln_cnt).item_attribute  := get_def_info_rec.item_attribute;  -- ���ڑ���
      gt_item_def_tab(ln_cnt).item_essential  := get_def_info_rec.item_essential;  -- �K�{�t���O
      gt_item_def_tab(ln_cnt).item_length     := get_def_info_rec.item_length;     -- ����(��������)
      gt_item_def_tab(ln_cnt).decim           := get_def_info_rec.decim;           -- ����(�����_�ȉ�)
    END LOOP def_info_loop;
    -- ��`��񂪎擾�ł��Ȃ��ꍇ�̓G���[
    IF ( ln_cnt = 0 ) THEN
      lv_error_token := cv_msg_xxwsh_13227;
      RAISE get_data_expt;
    END IF;
--
    --==============================================================
    -- M-1.6 OPM�݌ɉ�v����CLOSE�N���̎擾
    --==============================================================
    gv_opm_close_period := xxcmn_common_pkg.get_opminv_close_period;
--
    --==============================================================
    -- M-1.7 IN�p�����[�^�̏o��
    --==============================================================
    lv_parameter := xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_name_xxwsh
                     ,iv_name          => cv_msg_xxwsh_13228
                     ,iv_token_name1   => cv_tkn_upload_name   --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => cv_msg_xxwsh_13229   --����
                     ,iv_token_name2   => cv_tkn_file_name     --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => lv_csv_file_name     --����
                     ,iv_token_name3   => cv_tkn_file_id       --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => iv_file_id           --����
                     ,iv_token_name4   => cv_tkn_format        --�p�����[�^4(�g�[�N��)
                     ,iv_token_value4  => iv_format            --����
                   );
    -- �o�͂ɕ\��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_parameter
    );
    -- �o�͂ɕ\��(��s)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ���O�ɕ\��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_parameter
    );
    -- ���O�ɕ\��(��s)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �����Ɏg�p����Œ蕶��(���b�Z�[�W)���擾
--
    -- �i�ڋ敪
    gv_item_div_name     := xxccp_common_pkg.get_msg(
                              iv_application   => cv_appl_name_xxwsh
                             ,iv_name          => cv_msg_xxwsh_13242
                            );
    -- ���i�敪
    gv_product_div_name  := xxccp_common_pkg.get_msg(
                              iv_application   => cv_appl_name_xxwsh
                             ,iv_name          => cv_msg_xxwsh_13243
                            );
--
  EXCEPTION
    -- *** �p�����[�^NULL�G���[ ***
    WHEN get_param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_name_xxwsh
                    ,iv_name          => cv_msg_xxwsh_13192
                    ,iv_token_name1   => cv_tkn_parameter     --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => lv_error_token       --����
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_name_xxwsh
                    ,iv_name          => cv_msg_xxwsh_13193
                    ,iv_token_name1   => cv_tkn_prof_name     --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => lv_error_token       --����
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** INV�݌ɑg�DID�擾�G���[ ***
    WHEN get_org_id_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxwsh_13194            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_org_code
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�擾�G���[ ***
    WHEN get_data_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxwsh_13195            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���b�N�擾�G���[ ***
    WHEN global_lock_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxwsh_13196            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Q�ƃ^�C�v�擾�G���[ ***
    WHEN get_lookup_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxwsh_13197            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_lookup
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(M-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
     ov_errbuf     OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J����`��O ***
    blob_expt                 EXCEPTION;  -- BLOB�f�[�^�ϊ��G���[
    ins_err_expt              EXCEPTION;  -- �}���G���[
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_item_num               NUMBER;                             -- ���ڐ�
    ln_line_cnt               NUMBER;                             -- �s�J�E���^
    ln_item_cnt               NUMBER;                             -- ���ڐ��J�E���^
    lv_err_flag               VARCHAR2(1);                        -- �G���[�t���O
    lv_item_err_flag          VARCHAR2(1);                        -- �G���[�t���O�i���ځj
    ln_data_cnt               NUMBER;                             -- ���[�N�e�[�u���J�E���^
    -- *** ���[�J���E�e�[�u�� ***
    lt_if_data_tab   xxcmn_common3_pkg.g_file_data_tbl;  --  �e�[�u���^�ϐ���錾
    -- �`�F�b�N�p���
    TYPE g_check_data_ttype IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
    lt_check_data_tab  g_check_data_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- M-2.1 �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    xxcmn_common3_pkg.blob_to_varchar2(    -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id           -- �t�@�C���h�c
     ,ov_file_data => lt_if_data_tab       -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
--
    -- �G���[�t���O������
    lv_err_flag := cv_no;
    -- ���[�N�e�[�u���J�E���^�̏�����
    ln_data_cnt := cn_0;
--
    -- ���ڑÓ����`�F�b�NLOOP(M-2.2)
    <<check_loop>>
    FOR ln_line_cnt IN 1..lt_if_data_tab.COUNT LOOP
--
      -- �Ώی����擾
      gn_target_cnt := gn_target_cnt + 1;
--
      --==============================================================
      -- M-2.3 ���ڐ��̃`�F�b�N
      --==============================================================
      -- �f�[�^���ڐ����i�[
      ln_item_num := ( LENGTHB( lt_if_data_tab(ln_line_cnt) )
                   - ( LENGTHB( REPLACE(lt_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- ���ڐ�����v���Ȃ��ꍇ
      IF ( gn_item_num <> ln_item_num ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxwsh_13251    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_xxwsh_13229
                      ,iv_token_name2  => cv_tkn_count
                      ,iv_token_value2 => TO_CHAR(ln_item_num)
                      ,iv_token_name3  => cv_tkn_input_line_no
                      ,iv_token_value3 => TO_CHAR(ln_line_cnt)
                     );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O��Y�ɂ���
        lv_err_flag := cv_yes;
      -- ���ڐ�����v����ꍇ
      ELSE
        -- �G���[�t���O(����)�̏�����
        lv_item_err_flag := cv_no;
        --==============================================================
        -- M-2.4 �Ώۃf�[�^����
        --==============================================================
        <<get_column_loop>>
        FOR ln_item_cnt IN 1..gn_item_num LOOP
          -- �ϐ��ɍ��ڂ̒l���i�[
          lt_check_data_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(
                                               iv_char     => lt_if_data_tab(ln_line_cnt)  -- ������������
                                              ,iv_delim    => cv_msg_comma                 -- �f���~�^����
                                              ,in_part_num => ln_item_cnt                  -- �ԋp�Ώ�INDEX
                                            );
          --==============================================================
          -- M-2.5 �K�{/�^/�T�C�Y�`�F�b�N
          --==============================================================
          xxccp_common_pkg2.upload_item_check(
            iv_item_name    => gt_item_def_tab(ln_item_cnt).item_name          -- ���ږ���
           ,iv_item_value   => lt_check_data_tab(ln_item_cnt)                  -- ���ڂ̒l
           ,in_item_len     => gt_item_def_tab(ln_item_cnt).item_length        -- ���ڂ̒���(��������)
           ,in_item_decimal => gt_item_def_tab(ln_item_cnt).decim              -- ���ڂ̒����i�����_�ȉ��j
           ,iv_item_nullflg => gt_item_def_tab(ln_item_cnt).item_essential     -- �K�{�t���O
           ,iv_item_attr    => gt_item_def_tab(ln_item_cnt).item_attribute     -- ���ڂ̑���
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- �`�F�b�N�G���[�̏ꍇ
          IF ( lv_retcode <> cv_status_normal )  THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxcmn          -- �A�v���P�[�V�����Z�k��
                           ,iv_name          =>  cv_msg_xxcmn_10639          -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                           ,iv_token_value1  =>  TO_CHAR(ln_line_cnt)        -- �g�[�N���l1
                           ,iv_token_name2   =>  cv_tkn_err_msg              -- �g�[�N���R�[�h2
                           ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- �g�[�N���l2
                          );
             -- �o�͂ɕ\��
             FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
             );
             -- ���O�ɕ\��
             FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
               ,buff   => lv_errmsg
             );
             -- �G���[�t���O��Y�ɂ���
             lv_err_flag      := cv_yes;
             -- ���ڂ̃G���[�t���O��Y�ɂ���
             lv_item_err_flag := cv_yes;
          END IF;
--
          --==============================================================
          -- M-2.6 ���ʍ��ڂ̃}�C�i�X�l�`�F�b�N
          --==============================================================
          IF ( ln_item_cnt IN ( 4, 5, 6) ) THEN
            -- �}�C�i�X�l�̃`�F�b�N
            IF ( INSTR( lt_check_data_tab(ln_item_cnt), cv_minus ) > 0 ) THEN
              -- �g�[�N���p�̃��b�Z�[�W�ҏW
              lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh                      -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxwsh_13252                      -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1   =>  cv_tkn_column                           -- �g�[�N���R�[�h1
                             ,iv_token_value1  =>  gt_item_def_tab(ln_item_cnt).item_name  -- �g�[�N���l1
                            );
              lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxcmn          -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxcmn_10639          -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                             ,iv_token_value1  =>  TO_CHAR(ln_line_cnt)        -- �g�[�N���l1
                             ,iv_token_name2   =>  cv_tkn_err_msg              -- �g�[�N���R�[�h2
                             ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- �g�[�N���l2
                            );
               -- �o�͂ɕ\��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               -- ���O�ɕ\��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.LOG
                 ,buff   => lv_errmsg
               );
               -- �G���[�t���O��Y�ɂ���
               lv_err_flag      := cv_yes;
               -- ���ڂ̃G���[�t���O��Y�ɂ���
               lv_item_err_flag := cv_yes;
            END IF;
          END IF;
--
        END LOOP get_column_loop;
--
        -- 1�s�P�ʂŊe���ڂɃG���[���Ȃ��ꍇ
        IF ( lv_item_err_flag = cv_no ) THEN
          --==============================================================
          --  M-2.7 �o�׈˗��X�V�A�b�v���[�h���[�N�z��o�^
          --==============================================================
          ln_data_cnt := ln_data_cnt + 1;
          gt_upload_work_tab(ln_data_cnt).line_number    := ln_data_cnt;
          gt_upload_work_tab(ln_data_cnt).request_no     := lt_check_data_tab(1);
          gt_upload_work_tab(ln_data_cnt).item_code      := lt_check_data_tab(2);
          gt_upload_work_tab(ln_data_cnt).conv_item_code := lt_check_data_tab(3);
          gt_upload_work_tab(ln_data_cnt).pallet_quantity:= lt_check_data_tab(4);
          gt_upload_work_tab(ln_data_cnt).layer_quantity := lt_check_data_tab(5);
          gt_upload_work_tab(ln_data_cnt).case_quantity  := lt_check_data_tab(6);
          gt_upload_work_tab(ln_data_cnt).request_id     := cn_request_id;
        END IF;
--
      END IF;
--
    END LOOP check_loop;
--
    -- �s�v�Ȕz���DELETE
    lt_check_data_tab.DELETE;
--
    -- �S�f�[�^��1�����G���[���Ȃ��ꍇ
    IF ( lv_err_flag = cv_no ) THEN
      -- �J�E���^������
      ln_data_cnt := cn_0;
      --==============================================================
      --  M-2.8 �o�׈˗��X�V�A�b�v���[�h���[�N�o�^
      --==============================================================
      BEGIN
        FORALL ln_data_cnt IN 1 .. gt_upload_work_tab.COUNT
          INSERT INTO xxwsh_order_upload_work VALUES gt_upload_work_tab(ln_data_cnt);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SQLERRM;
          RAISE ins_err_expt;
      END;
    -- �S�f�[�^1���ł��G���[������ꍇ�i�t�@�C�����e�s���j
    ELSE
      -- �x���I���Ƃ���B
      ov_retcode  := cv_status_warn;
      -- �Ώی������X�L�b�v�����Ƃ���
      gn_skip_cnt := gn_target_cnt;
    END IF;
--
    -- �s�v�Ȕz���DELETE
    gt_upload_work_tab.DELETE;
--
  EXCEPTION
    -- *** BLOB�f�[�^�ϊ��G���[ ***
    WHEN blob_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmn_10640            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(gn_file_id)
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �}���G���[ ***
    WHEN ins_err_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxwsh_13198            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_xxwsh_13230
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => lv_errmsg
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_request_data
   * Description      : �o�׈˗��f�[�^�擾 (M-3)
   ***********************************************************************************/
  PROCEDURE get_ship_request_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_request_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J�����[�U�[��`��O ***
    data_skip_expt        EXCEPTION;   -- �X�L�b�v�f�[�^��O
--
    -- *** ���[�J���ϐ� ***
    lv_err_flag           VARCHAR2(1);    -- �G���[�t���O
    lv_ret_code           VARCHAR2(1);    -- ���^�[���R�[�h(���ʊ֐��p)
    lv_err_code           VARCHAR2(20);   -- �G���[���b�Z�[�W�R�[�h(���ʊ֐��p)
    lv_err_msg            VARCHAR2(5000); -- �G���[���b�Z�[�W(���ʊ֐��p)
    ln_result             NUMBER;         -- ��������(���ʊ֐��p)
    lv_exists             VARCHAR2(1);    -- �f�[�^���݊m�F�p
    lv_error_token        VARCHAR2(20);   -- �g�[�N�����b�Z�[�W�i�[�p
    ln_pallet_q_total     NUMBER;         -- �p���b�g�̑���
    ln_layer_q_total      NUMBER;         -- �i���̑���
    ln_line_case_q_total  NUMBER;         -- ���ׂ̃P�[�X����
    ln_line_q_total       NUMBER;         -- ���ׂ̑���
    ln_max_case_of_pallet NUMBER;         -- �p���b�g����ő�P�[�X��
    ln_pallet_quantity    NUMBER;         -- �p���b�g��
    ln_surplus_of_pallet  NUMBER;         -- �p���b�g���̗]��
    ln_layer_quantity     NUMBER;         -- �i��
    ln_case_quantity      NUMBER;         -- �P�[�X��
    ln_num_of_pallet      NUMBER;         -- �p���b�g����
    ln_sum_weight         NUMBER;         -- ���v�d��
    ln_sum_capacity       NUMBER;         -- ���v�e��
    ln_sum_pallet_weight  NUMBER;         -- ���v�p���b�g�d��
    ln_ins_cnt            NUMBER := 0;    -- �X�V�p���׃f�[�^����(�z��p)
    ln_plan_item_cnt      NUMBER;         -- �v�揤�i����
    lt_before_num_of_case xxcmn_item_mst2_v.num_of_cases%TYPE;  --�ύX�O�P�[�X����
    ln_before_toral_qty   NUMBER;         -- �ύX�O�̋��_�˗�����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���[�N�e�[�u���擾�J�[�\��
    CURSOR get_work_cur
    IS
      SELECT  xwouw.line_number      line_number     -- �sNo
             ,xwouw.request_no       request_no      -- �˗�No
             ,xwouw.item_code        item_code       -- �i�ڃR�[�h
             ,xwouw.conv_item_code   conv_item_code  -- �ύX��i�ڃR�[�h
             ,xwouw.pallet_quantity  pallet_quantity -- �p���b�g��
             ,xwouw.layer_quantity   layer_quantity  -- �i��
             ,xwouw.case_quantity    case_quantity   -- �P�[�X��
      FROM    xxwsh_order_upload_work xwouw          -- �o�׈˗��X�V�A�b�v���[�h���[�N�e�[�u��
      WHERE   xwouw.request_id = cn_request_id
      ORDER BY
              xwouw.request_no  --�˗�No
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_work_rec       get_work_cur%ROWTYPE;  -- �J�[�\���f�[�^���R�[�h
    l_order_rec          g_order_rtype;         -- �o�׈˗��f�[�^���R�[�h
    l_order_init_rec     g_order_rtype;         -- �o�׈˗��f�[�^���R�[�h(�������p)
    l_new_item_rec       g_new_item_rtype;      -- �ύX��̕i�ڃf�[�^���R�[�h
    l_new_item_init_rec  g_new_item_rtype;      -- �ύX��̕i�ڃf�[�^���R�[�h(�������p)
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    -- M-3.1 �o�׈˗��X�V���[�N�e�[�u���f�[�^�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_work_cur;
    <<work_data_loop>>
    LOOP
--
      -- ������
      lv_err_flag           := cv_no;                -- �G���[�t���O
      lv_ret_code           := cv_status_normal;     -- ���^�[���R�[�h(���ʊ֐��p)
      lv_err_code           := NULL;                 -- �G���[���b�Z�[�W�R�[�h(���ʊ֐��p)
      l_order_rec           := l_order_init_rec;     -- �o�׈˗��f�[�^
      l_new_item_rec        := l_new_item_init_rec;  -- �ύX��̕i�ڃf�[�^
      ln_pallet_q_total     := 0;                    -- �p���b�g�̑���
      ln_layer_q_total      := 0;                    -- �i���̑���
      ln_line_case_q_total  := 0;                    -- ���ׂ̃P�[�X����
      ln_line_q_total       := 0;                    -- ���ׂ̑���
      ln_max_case_of_pallet := 0;                    -- �p���b�g����ő�P�[�X��
      ln_pallet_quantity    := 0;                    -- �p���b�g��
      ln_surplus_of_pallet  := 0;                    -- �p���b�g���̗]��
      ln_layer_quantity     := 0;                    -- �i��
      ln_case_quantity      := 0;                    -- �P�[�X��
      ln_num_of_pallet      := 0;                    -- �p���b�g����
      ln_sum_weight         := 0;                    -- ���v�d��
      ln_sum_capacity       := 0;                    -- ���v�e��
      ln_sum_pallet_weight  := 0;                    -- ���v�p���b�g�d��
      ln_before_toral_qty   := 0;                    -- ���_�˗�����
--
      FETCH get_work_cur INTO l_get_work_rec;
      EXIT WHEN get_work_cur%NOTFOUND;
--
      BEGIN
        --==============================================================
        -- M-3.2-1 �o�׈˗��f�[�^�擾
        --==============================================================
        BEGIN
          SELECT  xott.transaction_type_name      transaction_type_name     -- ����^�C�v��
                 ,NVL( xlvv1.attribute1, cv_no )  status                    -- �X�e�[�^�X
                 ,NVL( xlvv2.attribute1, cv_no )  notif_status              -- �ʒm�X�e�[�^�X
                 ,xoha.order_header_id            order_header_id           -- �󒍃w�b�_�A�h�I��ID
                 ,xoha.request_no                 request_no                -- �˗�No
                 ,xoha.weight_capacity_class      weight_capacity_class     -- �d�ʗe�ϋ敪
                 ,xoha.freight_charge_class       freight_charge_class      -- ���敪�^
                 ,xoha.schedule_ship_date         schedule_ship_date        -- �o�ח\���
                 ,xoha.schedule_arrival_date      schedule_arrival_date     -- ���ח\���
                 ,xoha.based_weight               based_weight              -- ��{�d��
                 ,xoha.mixed_no                   mixed_no                  -- ���ڌ�No
                 ,xoha.head_sales_branch          head_sales_branch         -- �Ǌ����_
                 ,xoha.deliver_to                 deliver_to                -- �o�א�
                 ,xoha.deliver_from               deliver_from              -- �o�׌��ۊǏꏊ
                 ,xoha.deliver_from_id            deliver_from_id           -- �o�׌�ID
                 ,xola.rowid                      xola_rowid                -- ROWID
                 ,xola.order_line_id              order_line_id             -- �󒍖��׃A�h�I��ID
                 ,xola.automanual_reserve_class   automanual_reserve_class  -- �����蓮�����敪
                 ,xola.request_item_code          request_item_code         -- �˗��i��
                 ,xola.pallet_quantity            pallet_quantity           -- �p���b�g��
                 ,xola.layer_quantity             layer_quantity            -- �i��
                 ,xola.case_quantity              case_quantity             -- �P�[�X��
                 ,xola.shipped_quantity           shipped_quantity          -- �o�׎��ѐ���
                 ,xola.based_request_quantity     based_request_quantity    -- ���_�˗�����
          INTO    l_order_rec.transaction_type_name
                 ,l_order_rec.status
                 ,l_order_rec.notif_status
                 ,l_order_rec.order_header_id
                 ,l_order_rec.request_no
                 ,l_order_rec.weight_capacity_class
                 ,l_order_rec.freight_charge_class
                 ,l_order_rec.schedule_ship_date
                 ,l_order_rec.schedule_arrival_date
                 ,l_order_rec.based_weight
                 ,l_order_rec.mixed_no
                 ,l_order_rec.head_sales_branch
                 ,l_order_rec.deliver_to
                 ,l_order_rec.deliver_from
                 ,l_order_rec.deliver_from_id
                 ,l_order_rec.xola_rowid
                 ,l_order_rec.order_line_id
                 ,l_order_rec.automanual_reserve_class
                 ,l_order_rec.request_item_code
                 ,l_order_rec.pallet_quantity
                 ,l_order_rec.layer_quantity
                 ,l_order_rec.case_quantity
                 ,l_order_rec.shipped_quantity
                 ,l_order_rec.based_request_quantity
          FROM    xxwsh_order_headers_all      xoha  -- �󒍃w�b�_�A�h�I��
                 ,xxwsh_order_lines_all        xola  -- �󒍖��׃A�h�I��
                 ,xxwsh_oe_transaction_types_v xott  -- �󒍃^�C�v���VIEW
                 ,xxcmn_lookup_values2_v       xlvv1 -- �N�C�b�N�R�[�h���VIEW2�@
                 ,xxcmn_lookup_values2_v       xlvv2 -- �N�C�b�N�R�[�h���VIEW2�A
          WHERE   xoha.request_no                = l_get_work_rec.request_no
          AND     xoha.latest_external_flag      = cv_yes
          AND     xoha.order_header_id           = xola.order_header_id
          AND     xoha.order_type_id             = xott.transaction_type_id
          AND     xola.request_item_code         = l_get_work_rec.item_code
          AND     NVL( xola.delete_flag, cv_no ) = cv_no
          AND     xlvv1.lookup_type              = cv_lookup_t_status
          AND     xlvv1.lookup_code              = xoha.req_status
          AND     xlvv2.lookup_type              = cv_lookup_n_status
          AND     xlvv2.lookup_code              = xoha.notif_status
          ;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13199          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_get_work_rec.request_no   -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_item_code            -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.item_code    -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_get_work_rec.line_number  -- �g�[�N���l3
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v
          RAISE data_skip_expt;
        END;
--
        --==============================================================
        -- M-3.2-2 �C�Ӎ��ڂ̃f�[�^�ݒ�
        --==============================================================
        -- �ύX��i�ڂ�NULL�̏ꍇ
        IF ( l_get_work_rec.conv_item_code IS NULL ) THEN
          -- �o�׈˗��̈˗��i�ڂƂ���i�i�ڂ̕ύX�Ȃ��j
          l_get_work_rec.conv_item_code  := l_order_rec.request_item_code;
        END IF;
        -- �p���b�g����NULL�̏ꍇ
        IF ( l_get_work_rec.pallet_quantity IS NULL ) THEN
          -- �o�׈˗��̃p���b�g���Ƃ���i�p���b�g���̕ύX�Ȃ��j
          l_get_work_rec.pallet_quantity := l_order_rec.pallet_quantity;
        END IF;
        -- �i����NULL�̏ꍇ
        IF ( l_get_work_rec.layer_quantity IS NULL ) THEN
          -- �o�׈˗��̒i���Ƃ���i�i���̕ύX�Ȃ��j
          l_get_work_rec.layer_quantity  := l_order_rec.layer_quantity;
        END IF;
        -- �P�[�X����NULL�̏ꍇ
        IF ( l_get_work_rec.case_quantity IS NULL ) THEN
          -- �o�׈˗��̃P�[�X�Ƃ���i�P�[�X���̕ύX�Ȃ��j
          l_get_work_rec.case_quantity   := l_order_rec.case_quantity;
        END IF;
--
        --==============================================================
        -- M-3.3 �Ó����`�F�b�N
        --==============================================================
--
        -- 3-1.OPM�݌ɉ�v���Ԃ̃`�F�b�N
        IF ( gv_opm_close_period >= TO_CHAR( l_order_rec.schedule_ship_date, cv_yyyymm ) ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13238                                    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no                                     -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no                                -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_ship_date                                      -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  TO_CHAR( l_order_rec.schedule_ship_date, cv_yyyymm )  -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_input_line_no                                  -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_get_work_rec.line_number                            -- �g�[�N���l3
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-2.����^�C�v�̃`�F�b�N
        BEGIN
          SELECT cv_yes    data_exists
          INTO   lv_exists
          FROM   xxcmn_lookup_values2_v xlvv
          WHERE  xlvv.lookup_type = cv_lookup_process_upload
          AND    xlvv.meaning     = l_order_rec.transaction_type_name
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13200          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- �g�[�N���l2
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END;
--
        -- 3-3.�X�e�[�^�X�̃`�F�b�N
        IF ( l_order_rec.status <> cv_yes ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13201          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- �g�[�N���l2
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-4.�ʒm�X�e�[�^�X�̃`�F�b�N
        IF ( l_order_rec.notif_status <> cv_yes ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13202          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- �g�[�N���l2
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-5.�d�ʗe�ϋ敪�̃`�F�b�N
        IF ( l_order_rec.weight_capacity_class <> cv_weight ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13203          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- �g�[�N���l2
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-6.�蓮�����ς݂łȂ����Ƃ̃`�F�b�N
        IF ( l_order_rec.automanual_reserve_class = cv_manual ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13204          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- �g�[�N���l2
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-7.�ύX�O�̒l�ƕύX��̒l������łȂ����Ƃ��`�F�b�N
        IF (
              ( l_get_work_rec.conv_item_code  = l_order_rec.request_item_code )
              AND
              ( l_get_work_rec.pallet_quantity = l_order_rec.pallet_quantity )
              AND
              ( l_get_work_rec.layer_quantity  = l_order_rec.layer_quantity )
              AND
              ( l_get_work_rec.case_quantity   = l_order_rec.case_quantity )
            ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                         -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13205                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no                          -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_order_rec.request_no                     -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_item_code                           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_get_work_rec.item_code                   -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_pallet_q                            -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  TO_CHAR( l_get_work_rec.pallet_quantity )  -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_layer_q                             -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  TO_CHAR( l_get_work_rec.layer_quantity )   -- �g�[�N���l5
                       ,iv_token_name5   =>  cv_tkn_case_q                              -- �g�[�N���R�[�h4
                       ,iv_token_value5  =>  TO_CHAR( l_get_work_rec.case_quantity )    -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_input_line_no                       -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  l_get_work_rec.line_number                 -- �g�[�N���l6
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-8.�X�V�O�̕i�ڂ̃`�F�b�N
        BEGIN
          SELECT  ximv.num_of_cases num_of_cases
          INTO    lt_before_num_of_case
          FROM    xxcmn_item_mst2_v        ximv
                 ,xxcmn_item_categories2_v xicv1
                 ,xxcmn_item_categories2_v xicv2
          WHERE   ximv.item_no                = l_order_rec.request_item_code
          AND     ximv.start_date_active     <= cd_sysdate
          AND     ximv.end_date_active       >= cd_sysdate
          AND     ximv.ship_class             = cv_ship_class_1       -- �o�׋敪    �F�o�׉�
          AND     ximv.obsolete_class         = cv_obsolete_class_0   -- �p�~�敪    �F�p�~����Ă��Ȃ�
          AND     ximv.rate_class             = cv_rate_class_0       -- ���敪      �F�W������
          AND     ximv.weight_capacity_class  = cv_weight             -- �d�ʗe�ϋ敪�F�d��
          AND     (
                     (
                       ( ximv.item_id    = ximv.parent_item_id )
                       AND
                       ( ximv.sales_div  = cv_sales_div_1 )
                     )
                     OR
                     (
                       ( ximv.item_id   <> ximv.parent_item_id )
                     )
                  )                                                   -- �e�i�ڂŔ���Ώۂ��q�i��
          AND     ximv.item_id                = xicv1.item_id
          AND     xicv1.category_set_name     = gv_item_div_name      -- �i�ڋ敪
          AND     xicv1.segment1              = cv_item_div_5         -- �i�ڋ敪    �F���i
          AND     ximv.item_id                = xicv2.item_id
          AND     xicv2.category_set_name     = gv_product_div_name   -- ���i�敪
          AND     xicv2.segment1              = cv_product_div_2      -- ���i�敪    �F�h�����N
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���b�Z�[�W�ҏW
            lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxwsh_13206              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_request_no               -- �g�[�N���R�[�h1
                         ,iv_token_value1  =>  l_order_rec.request_no          -- �g�[�N���l1
                         ,iv_token_name2   =>  cv_tkn_item_code                -- �g�[�N���R�[�h2
                         ,iv_token_value2  =>  l_order_rec.request_item_code   -- �g�[�N���l2
                         ,iv_token_name3   =>  cv_tkn_input_line_no            -- �g�[�N���R�[�h3
                         ,iv_token_value3  =>  l_get_work_rec.line_number      -- �g�[�N���l3
                        );
            -- �o�͂ɕ\��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- ���O�ɕ\��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg
            );
            -- �G���[�t���O�𗧂āA�ȍ~�̃`�F�b�N�����{
            lv_err_flag := cv_yes;
        END;
--
        -- 3-9.�X�V��̕i�ڂ̃`�F�b�N
        BEGIN
          SELECT  ximv.item_id            item_id             -- �i��ID
                 ,ximv.parent_item_id     parent_item_id      -- �e�i��ID
                 ,ximv.inventory_item_id  inventory_item_id   -- INV�i��ID
                 ,ximv.item_no            item_no             -- �i�ڃR�[�h
                 ,ximv.conv_unit          conv_unit           -- ���o�Ɋ��Z�P��
                 ,ximv.num_of_cases       num_of_cases        -- �P�[�X����
                 ,ximv.max_palette_steps  max_palette_steps   -- �p���b�g����ő�i��
                 ,ximv.delivery_qty       delivery_qty        -- �z��
                 ,ximv.item_um            item_um             -- �P��
                 ,ximv.num_of_deliver     num_of_deliver      -- �o�ד���
          INTO    l_new_item_rec.item_id                      -- �i��ID
                 ,l_new_item_rec.parent_item_id               -- �e�i��ID
                 ,l_new_item_rec.inventory_item_id            -- INV�i��ID
                 ,l_new_item_rec.item_no                      -- �i�ڃR�[�h
                 ,l_new_item_rec.conv_unit                    -- ���o�Ɋ��Z�P��
                 ,l_new_item_rec.num_of_cases                 -- �P�[�X����
                 ,l_new_item_rec.max_palette_steps            -- �p���b�g����ő�i��
                 ,l_new_item_rec.delivery_qty                 -- �z��
                 ,l_new_item_rec.item_um                      -- �P��
                 ,l_new_item_rec.num_of_deliver               -- �o�ד���
          FROM    xxcmn_item_mst2_v        ximv
                 ,xxcmn_item_categories2_v xicv1
                 ,xxcmn_item_categories2_v xicv2
          WHERE   ximv.item_no                = l_get_work_rec.conv_item_code
          AND     ximv.start_date_active     <= cd_sysdate
          AND     ximv.end_date_active       >= cd_sysdate
          AND     ximv.ship_class             = cv_ship_class_1       -- �o�׋敪    �F�o�׉�
          AND     ximv.obsolete_class         = cv_obsolete_class_0   -- �p�~�敪    �F�p�~����Ă��Ȃ�
          AND     ximv.rate_class             = cv_rate_class_0       -- ���敪      �F�W������
          AND     ximv.weight_capacity_class  = cv_weight             -- �d�ʗe�ϋ敪�F�d��
          AND     (
                     (
                       ( ximv.item_id    = ximv.parent_item_id )
                       AND
                       ( ximv.sales_div  = cv_sales_div_1 )
                     )
                     OR
                     (
                       ( ximv.item_id   <> ximv.parent_item_id )
                     )
                  )                                                   -- �e�i�ڂŔ���Ώۂ��q�i��
          AND     ximv.item_id                = xicv1.item_id
          AND     xicv1.category_set_name     = gv_item_div_name      -- �i�ڋ敪
          AND     xicv1.segment1              = cv_item_div_5         -- �i�ڋ敪    �F���i
          AND     ximv.item_id                = xicv2.item_id
          AND     xicv2.category_set_name     = gv_product_div_name   -- ���i�敪
          AND     xicv2.segment1              = cv_product_div_2      -- ���i�敪    �F�h�����N
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���b�Z�[�W�ҏW
            lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxwsh_13207              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_request_no               -- �g�[�N���R�[�h1
                         ,iv_token_value1  =>  l_order_rec.request_no          -- �g�[�N���l1
                         ,iv_token_name2   =>  cv_tkn_item_code                -- �g�[�N���R�[�h2
                         ,iv_token_value2  =>  l_get_work_rec.conv_item_code   -- �g�[�N���l2
                         ,iv_token_name3   =>  cv_tkn_input_line_no            -- �g�[�N���R�[�h3
                         ,iv_token_value3  =>  l_get_work_rec.line_number      -- �g�[�N���l3
                        );
            -- �o�͂ɕ\��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- ���O�ɕ\��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg
            );
            -- ���`�F�b�N�ȍ~�̃G���[�̓f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END;
--
        --------------------------------------
        -- 3-10.�ϊ���i�ڂ̑Ó����`�F�b�N
        --------------------------------------
--
        -- 3-10-1.���o�Ɋ��Z�P�ʂ�NULL�`�F�b�N
        IF ( l_new_item_rec.conv_unit IS NULL ) THEN
          -- �g�[�N�������擾
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxwsh_13244  -- ���b�Z�[�W�R�[�h
                            );
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh             -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13208             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_column                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  lv_error_token                 -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no              -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_order_rec.request_no         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code               -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_new_item_rec.item_no         -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_input_line_no           -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  l_get_work_rec.line_number     -- �g�[�N���l4
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-2.�P�[�X������NULL�A0�`�F�b�N
        IF ( NVL( l_new_item_rec.num_of_cases, cn_0 ) = cn_0 ) THEN
          -- �g�[�N�������擾
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxwsh_13245  -- ���b�Z�[�W�R�[�h
                            );
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh             -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13208             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_column                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  lv_error_token                 -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no              -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_order_rec.request_no         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code               -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_new_item_rec.item_no         -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_input_line_no           -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  l_get_work_rec.line_number     -- �g�[�N���l4
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-3.�p���b�g����ő�i����NULL�A0�`�F�b�N
        IF ( NVL( l_new_item_rec.max_palette_steps, cn_0 ) = cn_0 ) THEN
          -- �g�[�N�������擾
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxwsh_13246  -- ���b�Z�[�W�R�[�h
                            );
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh             -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13208             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_column                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  lv_error_token                 -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no              -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_order_rec.request_no         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code               -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_new_item_rec.item_no         -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_input_line_no           -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  l_get_work_rec.line_number     -- �g�[�N���l4
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-4.�z����NULL�A0�`�F�b�N
        IF ( NVL( l_new_item_rec.delivery_qty, cn_0 ) = cn_0 ) THEN
          -- �g�[�N�������擾
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxwsh_13247  -- ���b�Z�[�W�R�[�h
                            );
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh           -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13208           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_column                -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  lv_error_token               -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no            -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  l_order_rec.request_no       -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code             -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_new_item_rec.item_no       -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_input_line_no         -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  l_get_work_rec.line_number   -- �g�[�N���l4
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-5.INV�i�ځi�c�Ƒ��̕i�ځj�̑Ώۃ`�F�b�N
        BEGIN
          SELECT  cv_yes  data_exisits
          INTO    lv_exists
          FROM    mtl_system_items_b  msib
          WHERE   msib.inventory_item_id              =  l_new_item_rec.inventory_item_id
          AND     msib.organization_id                =  gn_inv_org_id
          AND     msib.inventory_item_status_code     <> cv_inactive
          AND     msib.customer_order_enabled_flag    =  cv_yes  -- �ڋq�󒍉\�FY
          AND     msib.mtl_transactions_enabled_flag  =  cv_yes  -- ����\    �FY
          AND     msib.stock_enabled_flag             =  cv_yes  -- �݌ɕۗL�\�FY
          AND     msib.returnable_flag                =  cv_yes  -- �ԕi�\    �FY
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���b�Z�[�W�ҏW
            lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh           -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxwsh_13209           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_request_no            -- �g�[�N���R�[�h2
                         ,iv_token_value1  =>  l_order_rec.request_no       -- �g�[�N���l2
                         ,iv_token_name2   =>  cv_tkn_item_code             -- �g�[�N���R�[�h3
                         ,iv_token_value2  =>  l_new_item_rec.item_no       -- �g�[�N���l3
                         ,iv_token_name3   =>  cv_tkn_input_line_no         -- �g�[�N���R�[�h4
                         ,iv_token_value3  =>  l_get_work_rec.line_number   -- �g�[�N���l4
                        );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END;
--
        -- 3-10-6.�q�i�ځE���ވȊO�̏ꍇ�̐e�i�ڂ̔���Ώۋ敪�`�F�b�N(�e�i�ڂ̏ꍇ��3-9�Ń`�F�b�N)
        IF (
             ( l_new_item_rec.item_id <> l_new_item_rec.parent_item_id )
             AND
             ( SUBSTRB( l_new_item_rec.item_no, 1, 1 ) NOT IN ( cv_item_code_5, cv_item_code_6 ) )
           ) THEN
          BEGIN
            SELECT  cv_yes  data_exisits
            INTO    lv_exists
            FROM    mtl_system_items_b  msib
                  , ic_item_mst_b       iimb_c
                  , ic_item_mst_b       iimb_p
                  , xxcmn_item_mst_b    ximb
            WHERE   msib.inventory_item_id  =       l_new_item_rec.inventory_item_id
            AND     msib.organization_id    =       gn_inv_org_id
            AND     msib.segment1           =       iimb_c.item_no
            AND     iimb_c.item_id          =       ximb.item_id
            AND     ximb.parent_item_id     =       iimb_p.item_id
            AND     iimb_p.attribute26      =       cv_sales_div_1
            AND     l_order_rec.schedule_arrival_date  BETWEEN ximb.start_date_active
                                                       AND     NVL(ximb.end_date_active, l_order_rec.schedule_arrival_date)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���b�Z�[�W�ҏW
              lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh           -- �A�v���P�[�V�����Z�k��
                           ,iv_name          =>  cv_msg_xxwsh_13210           -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   =>  cv_tkn_request_no            -- �g�[�N���R�[�h2
                           ,iv_token_value1  =>  l_order_rec.request_no       -- �g�[�N���l2
                           ,iv_token_name2   =>  cv_tkn_item_code             -- �g�[�N���R�[�h3
                           ,iv_token_value2  =>  l_new_item_rec.item_no       -- �g�[�N���l3
                           ,iv_token_name3   =>  cv_tkn_input_line_no         -- �g�[�N���R�[�h4
                           ,iv_token_value3  =>  l_get_work_rec.line_number   -- �g�[�N���l4
                          );
              -- �o�͂ɕ\��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              -- ���O�ɕ\��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
              -- �f�[�^�X�L�b�v��O�Ƃ���
              RAISE data_skip_expt;
          END;
        END IF;
--
        --==============================================================
        -- M-3.4 �����̌v�Z
        --==============================================================
--
        -- 4-1.�p���b�g�̑������擾(�p���b�g���~�z���~�p���b�g����ő�i��)
        ln_pallet_q_total    := l_get_work_rec.pallet_quantity * l_new_item_rec.delivery_qty * l_new_item_rec.max_palette_steps;
--
        -- 4-2.�i���̑������擾(�i���~�z��)
        ln_layer_q_total     := l_get_work_rec.layer_quantity * l_new_item_rec.delivery_qty;
--
        -- 4-3.����(�P�[�X�P��)���擾
        ln_line_case_q_total := ( ln_pallet_q_total + ln_layer_q_total + l_get_work_rec.case_quantity );
--
        -- 4-4.����(����)���擾(����(�P�[�X�P��) �~�P�[�X����)
        ln_line_q_total      := ln_line_case_q_total * l_new_item_rec.num_of_cases;
--
        --==============================================================
        -- M-3.5 �������o�ד����̐����{���`�F�b�N(�o�ד���������ꍇ�̂�)
        --==============================================================
        IF ( l_new_item_rec.num_of_deliver IS NOT NULL ) THEN
          IF ( MOD( ln_line_q_total, l_new_item_rec.num_of_deliver ) <> cn_0 ) THEN
             -- ���b�Z�[�W�ҏW
             lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxwsh                        -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxwsh_13211                        -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1   =>  cv_tkn_quantity                           -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  TO_CHAR( ln_line_q_total )                -- �g�[�N���l1
                          ,iv_token_name2   =>  cv_tkn_num_of_deliver                     -- �g�[�N���R�[�h2
                          ,iv_token_value2  =>  TO_CHAR( l_new_item_rec.num_of_deliver )  -- �g�[�N���l2
                          ,iv_token_name3   =>  cv_tkn_request_no                         -- �g�[�N���R�[�h3
                          ,iv_token_value3  =>  l_order_rec.request_no                    -- �g�[�N���l3
                          ,iv_token_name4   =>  cv_tkn_item_code                          -- �g�[�N���R�[�h4
                          ,iv_token_value4  =>  l_new_item_rec.item_no                    -- �g�[�N���l4
                          ,iv_token_name5   =>  cv_tkn_input_line_no                      -- �g�[�N���R�[�h5
                          ,iv_token_value5  =>  l_get_work_rec.line_number                -- �g�[�N���l5
                         );
              -- �o�͂ɕ\��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              -- ���O�ɕ\��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
              -- �f�[�^�X�L�b�v��O�Ƃ���
              RAISE data_skip_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- M-3.6 �p���b�g���E�i���E�P�[�X���̍Čv�Z
        --==============================================================
--
        -- 6-1.�p���b�g������̍ő�P�[�X��(�z���~�p���b�g����ő�i��)
        ln_max_case_of_pallet := l_new_item_rec.delivery_qty * l_new_item_rec.max_palette_steps;
--
        -- 6-2.�p���b�g���̎擾
        IF ( ln_max_case_of_pallet <> cn_0 ) THEN
          -- �p���b�g��(����(�P�[�X�P��)���p���b�g����ő�P�[�X��)
          ln_pallet_quantity    := TRUNC( ln_line_case_q_total / ln_max_case_of_pallet );
        ELSE
          -- �p���b�g������̍ő�P�[�X����0�̏ꍇ�̓p���b�g����0
          ln_pallet_quantity    := cn_0;  --�p���b�g
        END IF;
        -- �Čv�Z�̌��ʃp���b�g����3���𒴂���ꍇ�G���[
        IF ( LENGTHB( TO_CHAR( ln_pallet_quantity ) ) > 3 ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxwsh_13212              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_request_no               -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  l_order_rec.request_no          -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_item_code                -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  l_new_item_rec.item_no          -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_pallet_q                 -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  TO_CHAR( ln_pallet_quantity )   -- �g�[�N���l3
                        ,iv_token_name4   =>  cv_tkn_input_line_no            -- �g�[�N���R�[�h4
                        ,iv_token_value4  =>  l_get_work_rec.line_number      -- �g�[�N���l4
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END IF;
--
        -- 6-3.�i���̎擾(�p���b�g���̗]�聦1���z��)
        ln_surplus_of_pallet := MOD( ln_line_case_q_total, ln_max_case_of_pallet ); --��1
        ln_layer_quantity    := TRUNC( ln_surplus_of_pallet / l_new_item_rec.delivery_qty);
--
        -- 6-4.�P�[�X���̎擾(�p���b�g���̗]���z���Ŋ������]��)
        ln_case_quantity     := MOD( ln_surplus_of_pallet, l_new_item_rec.delivery_qty );
--
        -- 6-5.�p���b�g�����̎擾
        IF ( ln_surplus_of_pallet <> cn_0 ) THEN
          -- �p���b�g�����{1�i�[�����̃p���b�g�j
          ln_num_of_pallet := ln_pallet_quantity + 1;
        ELSE
          ln_num_of_pallet := ln_pallet_quantity;
        END IF;
--
        -- 6-6.���_�˗����ʂ̍Čv�Z�i�ύX�O�̋��_�˗����ʁ��ύX�O�̕i�ڂ̃P�[�X�����~�ύX��̕i�ڂ̃P�[�X�����j
        ln_before_toral_qty := ( l_order_rec.based_request_quantity / lt_before_num_of_case ) * l_new_item_rec.num_of_cases;
--
        --==============================================================
        -- M-3.7 �d�ʂ̍Čv�Z
        --==============================================================
--
        -- ���ʊ֐��u�ύڌ����`�F�b�N(���v�l�Z�o)�v�ɂ��擾
        xxwsh_common910_pkg.calc_total_value(
           iv_item_no            =>  l_new_item_rec.item_no          -- �i�ڃR�[�h
          ,in_quantity           =>  ln_line_q_total                 -- ���ׂ̑���
          ,ov_retcode            =>  lv_ret_code                     -- ���^�[���R�[�h
          ,ov_errmsg_code        =>  lv_err_code                     -- �G���[���b�Z�[�W�R�[�h
          ,ov_errmsg             =>  lv_err_msg                      -- �G���[���b�Z�[�W
          ,on_sum_weight         =>  ln_sum_weight                   -- ���v�d��
          ,on_sum_capacity       =>  ln_sum_capacity                 -- ���v�e��
          ,on_sum_pallet_weight  =>  ln_sum_pallet_weight            -- ���v�p���b�g�d��
          ,id_standard_date      =>  l_order_rec.schedule_ship_date  -- �o�ח\���
        );
        -- ���^�[���R�[�h������łȂ��ꍇ
        IF ( lv_ret_code <> cv_status_normal ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13213                                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no                                           -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  l_get_work_rec.request_no                                   -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_ship_date                                            -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  TO_CHAR( l_order_rec.schedule_ship_date, cv_yyyymmdd_sla )  -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code                                            -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  l_new_item_rec.item_no                                      -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_quantity                                             -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  TO_CHAR( ln_line_q_total )                                  -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_input_line_no                                        -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  l_get_work_rec.line_number                                  -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_err_msg                                              -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  lv_err_msg                                                  -- �g�[�N���l6
                      );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �f�[�^�X�L�b�v��O�Ƃ���
          RAISE data_skip_expt;
        END IF;
--
        --==============================================================
        -- M-3.8 ���׍X�V�p�̔z��ɒl��ݒ�
        --==============================================================
--
        -- �`�F�b�N�ŃG���[���Ȃ��ꍇ
        IF ( lv_err_flag = cv_no ) THEN
          ln_ins_cnt := ln_ins_cnt + 1;
          gt_ship_line_data_tab(ln_ins_cnt).line_number                 :=  l_get_work_rec.line_number;              -- �sNo
          gt_ship_line_data_tab(ln_ins_cnt).automanual_reserve_class    :=  l_order_rec.automanual_reserve_class;    -- �����蓮�����敪
          gt_ship_line_data_tab(ln_ins_cnt).order_header_id             :=  l_order_rec.order_header_id;             -- �󒍃w�b�_�A�h�I��ID
          gt_ship_line_data_tab(ln_ins_cnt).request_no                  :=  l_order_rec.request_no;                  -- �˗�No
          gt_ship_line_data_tab(ln_ins_cnt).mixed_no                    :=  l_order_rec.mixed_no;                    -- ���ڌ�No
          gt_ship_line_data_tab(ln_ins_cnt).head_sales_branch           :=  l_order_rec.head_sales_branch;           -- �Ǌ����_
          gt_ship_line_data_tab(ln_ins_cnt).deliver_to                  :=  l_order_rec.deliver_to;                  -- �o�א�
          gt_ship_line_data_tab(ln_ins_cnt).deliver_from                :=  l_order_rec.deliver_from;                -- �o�׌��ۊǏꏊ
          gt_ship_line_data_tab(ln_ins_cnt).deliver_from_id             :=  l_order_rec.deliver_from_id;             -- �o�׌�ID
          gt_ship_line_data_tab(ln_ins_cnt).schedule_ship_date          :=  l_order_rec.schedule_ship_date;          -- �o�ɗ\���
          gt_ship_line_data_tab(ln_ins_cnt).schedule_arrival_date       :=  l_order_rec.schedule_arrival_date;       -- ���ח\���
          gt_ship_line_data_tab(ln_ins_cnt).xola_rowid                  :=  l_order_rec.xola_rowid;                  -- ����ROWID
          gt_ship_line_data_tab(ln_ins_cnt).order_line_id               :=  l_order_rec.order_line_id;               -- �󒍖��׃A�h�I��ID
          gt_ship_line_data_tab(ln_ins_cnt).shipping_inventory_item_id  :=  l_new_item_rec.inventory_item_id;        -- �o�וi��ID
          gt_ship_line_data_tab(ln_ins_cnt).shipping_item_code          :=  l_new_item_rec.item_no;                  -- �o�וi��
          gt_ship_line_data_tab(ln_ins_cnt).quantity                    :=  ln_line_q_total;                         -- ����
          gt_ship_line_data_tab(ln_ins_cnt).uom_code                    :=  l_new_item_rec.item_um;                  -- �P��
          gt_ship_line_data_tab(ln_ins_cnt).shipped_quantity            :=  ( l_order_rec.shipped_quantity
                                                                              * l_new_item_rec.num_of_cases );       -- �o�׎��ѐ���
          gt_ship_line_data_tab(ln_ins_cnt).based_request_quantity      :=  ln_before_toral_qty;                     -- ���_���ѐ���
          gt_ship_line_data_tab(ln_ins_cnt).request_item_id             :=  l_new_item_rec.inventory_item_id;        -- �˗��i��ID
          gt_ship_line_data_tab(ln_ins_cnt).request_item_code           :=  l_new_item_rec.item_no;                  -- �˗��i��
          gt_ship_line_data_tab(ln_ins_cnt).po_number                   :=  NULL;                                    -- ����NO
          gt_ship_line_data_tab(ln_ins_cnt).pallet_quantity             :=  ln_pallet_quantity;                      -- �p���b�g��
          gt_ship_line_data_tab(ln_ins_cnt).layer_quantity              :=  ln_layer_quantity;                       -- �i��
          gt_ship_line_data_tab(ln_ins_cnt).case_quantity               :=  ln_case_quantity;                        -- �P�[�X��
          gt_ship_line_data_tab(ln_ins_cnt).weight                      :=  ln_sum_weight;                           -- �d��
          gt_ship_line_data_tab(ln_ins_cnt).capacity                    :=  ln_sum_capacity;                         -- �e��
          gt_ship_line_data_tab(ln_ins_cnt).pallet_weight               :=  ln_sum_pallet_weight;                    -- �p���b�g�d��
          gt_ship_line_data_tab(ln_ins_cnt).pallet_qty                  :=  ln_num_of_pallet;                        -- �p���b�g����
          gt_ship_line_data_tab(ln_ins_cnt).shipping_request_if_flg     :=  cv_no;                                   -- �o�׈˗��C���^�t�F�[�X�σt���O
          gt_ship_line_data_tab(ln_ins_cnt).shipping_result_if_flg      :=  cv_no;                                   -- �o�׎��уC���^�t�F�[�X�σt���O
          gt_ship_line_data_tab(ln_ins_cnt).last_updated_by             :=  cn_last_updated_by;                      -- �ŏI�X�V��
          gt_ship_line_data_tab(ln_ins_cnt).last_update_date            :=  cd_last_update_date;                     -- �ŏI�X�V��
          gt_ship_line_data_tab(ln_ins_cnt).last_update_login           :=  cn_last_update_login;                    -- �ŏI�X�V���O�C��
          gt_ship_line_data_tab(ln_ins_cnt).request_id                  :=  cn_request_id;                           -- �v��ID
          gt_ship_line_data_tab(ln_ins_cnt).program_application_id      :=  cn_program_application_id;               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          gt_ship_line_data_tab(ln_ins_cnt).program_id                  :=  cn_program_id;                           -- �R���J�����g�E�v���O����ID
          gt_ship_line_data_tab(ln_ins_cnt).program_update_date         :=  cd_program_update_date;                  -- �v���O�����X�V��
        ELSE
           -- �X�L�b�v�����J�E���g
          gn_skip_cnt := gn_skip_cnt + 1;
          -- 1���ł��X�L�b�v�f�[�^������ꍇ�͌x���Ƃ���
          ov_retcode  := cv_status_warn;
        END IF;
--
      EXCEPTION
        -- �f�[�^�X�L�b�v��O
        WHEN data_skip_expt THEN
          -- �X�L�b�v�����J�E���g
          gn_skip_cnt := gn_skip_cnt + 1;
          -- 1���ł��X�L�b�v�f�[�^������ꍇ�͌x���Ƃ���
          ov_retcode  := cv_status_warn;
        END;
--
    END LOOP work_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_work_cur;
--
    -- ������
    lv_err_flag := cv_no;
--
    --==============================================================
    -- M-3.9 �����S���p�̑Ó����`�F�b�N�i���b�Z�[�W�o�͂̂݁j
    --==============================================================
    <<chk_emp_of_logi>>
    FOR i IN 1..gt_ship_line_data_tab.COUNT LOOP
--
      -- ������
      lv_ret_code      := cv_status_normal;
      lv_err_code      := NULL;
      lv_err_msg       := NULL;
      ln_result        := NULL;
      ln_plan_item_cnt := 0;
--
      -- 9-1.���ʊ֐��u�����\���A�h�I���̃`�F�b�N�v�ɂ�蕨���\���̑��݃`�F�b�N
      lv_ret_code := xxwsh_common_pkg.chk_sourcing_rules(
                        it_item_code          =>  gt_ship_line_data_tab(i).shipping_item_code  -- �o�וi��
                       ,it_base_code          =>  gt_ship_line_data_tab(i).head_sales_branch   -- �Ǌ����_
                       ,it_ship_to_code       =>  gt_ship_line_data_tab(i).deliver_to          -- �o�א�
                       ,it_delivery_whse_code =>  gt_ship_line_data_tab(i).deliver_from        -- �o�Ɍ��ۊǏꏊ
                       ,id_standard_date      =>  gt_ship_line_data_tab(i).schedule_ship_date  -- �o�ח\���
                     );
      -- ���^�[���R�[�h������łȂ��ꍇ
      IF ( lv_ret_code <> cv_status_normal ) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13231                                                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_request_no                                                        -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  gt_ship_line_data_tab(i).request_no                                      -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_item_code                                                         -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_hs_branch                                                         -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_deliver_to                                                        -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).deliver_to                                      -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_deliver_from                                                      -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  gt_ship_line_data_tab(i).deliver_from                                    -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_ship_date                                                         -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- �g�[�N���l6
                       ,iv_token_name7   =>  cv_tkn_input_line_no                                                     -- �g�[�N���R�[�h7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).line_number                                     -- �g�[�N���l7
                      );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O�𗧂Ă�
        lv_err_flag := cv_yes;
      END IF;
--
      ----------------------------------------------------------
      -- 9-2.���ʊ֐��u�o�׉ۃ`�F�b�N�v�ɂ��o�׉ۃ`�F�b�N
      ----------------------------------------------------------
--
      -- 9-2-1.�o�א�����(���i��)
      xxwsh_common910_pkg.check_shipping_judgment(
         iv_check_class      =>  cv_check_class_2                                     -- �`�F�b�N���@(�o�א�����(���i��))
        ,iv_base_cd          =>  gt_ship_line_data_tab(i).head_sales_branch           -- �Ǌ����_
        ,in_item_id          =>  gt_ship_line_data_tab(i).shipping_inventory_item_id  -- �o�וi��ID
        ,in_amount           =>  gt_ship_line_data_tab(i).quantity                    -- ���ׂ̑���
        ,id_date             =>  gt_ship_line_data_tab(i).schedule_arrival_date       -- ���ח\���
        ,in_deliver_from_id  =>  gt_ship_line_data_tab(i).deliver_from_id             -- �o�׌��ۊǏꏊID
        ,iv_request_no       =>  gt_ship_line_data_tab(i).request_no                  -- �˗�No
        ,ov_retcode          =>  lv_ret_code                                          -- ���^�[���R�[�h
        ,ov_errmsg_code      =>  lv_err_code                                          -- �G���[���b�Z�[�W�R�[�h
        ,ov_errmsg           =>  lv_err_msg                                           -- �G���[���b�Z�[�W
        ,on_result           =>  ln_result                                            -- ��������
      );
      -- ���^�[���R�[�h������łȂ��ꍇ
      IF ( lv_ret_code <> cv_status_normal ) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13248                                                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13233                                                          -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_arrival_date, cv_yyyymmdd_sla )  -- �g�[�N���l6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- �g�[�N���R�[�h7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- �g�[�N���l7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- �g�[�N���R�[�h8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- �g�[�N���l8
                       ,iv_token_name9   =>  cv_tkn_err_msg                                                              -- �g�[�N���R�[�h9
                       ,iv_token_value9  =>  lv_err_msg                                                                  -- �g�[�N���l9
                      );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O�𗧂Ă�
        lv_err_flag := cv_yes;
      -- �������ʂ�����łȂ��ꍇ
      ELSIF ( ln_result <> cn_ret_normal) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13232                                                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13233                                                          -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_arrival_date, cv_yyyymmdd_sla )  -- �g�[�N���l6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- �g�[�N���R�[�h7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- �g�[�N���l7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- �g�[�N���R�[�h8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- �g�[�N���l8
                      );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O�𗧂Ă�
        lv_err_flag := cv_yes;
      END IF;
--
      -- 9-2-2.�o�א�����(������)
      xxwsh_common910_pkg.check_shipping_judgment(
         iv_check_class      =>  cv_check_class_3                                     -- �`�F�b�N���@(�o�א�����(������))
        ,iv_base_cd          =>  gt_ship_line_data_tab(i).head_sales_branch           -- �Ǌ����_
        ,in_item_id          =>  gt_ship_line_data_tab(i).shipping_inventory_item_id  -- �o�וi��ID
        ,in_amount           =>  gt_ship_line_data_tab(i).quantity                    -- ���ׂ̑���
        ,id_date             =>  gt_ship_line_data_tab(i).schedule_arrival_date       -- ���ח\���
        ,in_deliver_from_id  =>  gt_ship_line_data_tab(i).deliver_from_id             -- �o�׌��ۊǏꏊID
        ,iv_request_no       =>  gt_ship_line_data_tab(i).request_no                  -- �˗�No
        ,ov_retcode          =>  lv_ret_code                                          -- ���^�[���R�[�h
        ,ov_errmsg_code      =>  lv_err_code                                          -- �G���[���b�Z�[�W�R�[�h
        ,ov_errmsg           =>  lv_err_msg                                           -- �G���[���b�Z�[�W
        ,on_result           =>  ln_result                                            -- ��������
      );
      -- ���^�[���R�[�h������łȂ��ꍇ
      IF ( lv_ret_code <> cv_status_normal ) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13248                                                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                          -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13234                                                       -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                        -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                      -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                         -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                         -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                          -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                             -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                         -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- �g�[�N���l6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                      -- �g�[�N���R�[�h7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                    -- �g�[�N���l7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                     -- �g�[�N���R�[�h8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                     -- �g�[�N���l8
                       ,iv_token_name9   =>  cv_tkn_err_msg                                                           -- �g�[�N���R�[�h9
                       ,iv_token_value9  =>  lv_err_msg                                                               -- �g�[�N���l9
                      );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O�𗧂Ă�
        lv_err_flag := cv_yes;
      -- �������ʂ����ʃI�[�o�[�̏ꍇ
      ELSIF ( ln_result = cn_ret_num_over) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13232                                                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13234                                                          -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )     -- �g�[�N���l6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- �g�[�N���R�[�h7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- �g�[�N���l7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- �g�[�N���R�[�h8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- �g�[�N���l8
                      );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O�𗧂Ă�
        lv_err_flag := cv_yes;
      -- �������ʂ��o�ג�~���G���[�̏ꍇ
      ELSIF ( ln_result = cn_ret_date_err) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxwsh_13235                                                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13234                                                          -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- �g�[�N���l4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- �g�[�N���R�[�h5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- �g�[�N���l5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- �g�[�N���R�[�h6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )     -- �g�[�N���l6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- �g�[�N���R�[�h7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- �g�[�N���l7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- �g�[�N���R�[�h8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- �g�[�N���l8
                      );
        -- �o�͂ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���O�ɕ\��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �G���[�t���O�𗧂Ă�
        lv_err_flag := cv_yes;
      END IF;
--
      -- 9-2-3.�o�א�����(����v��)�̎��{�ׁ̈A�v�揤�i�������擾
      SELECT COUNT(xsrv.rowid)
      INTO   ln_plan_item_cnt
      FROM   xxcmn_sourcing_rules2_v xsrv
      WHERE  xsrv.base_code           = gt_ship_line_data_tab(i).head_sales_branch
      AND    xsrv.item_code           = gt_ship_line_data_tab(i).shipping_item_code
      AND    xsrv.plan_item_flag      = cv_plan_item_flag
      AND    xsrv.start_date_active  <= gt_ship_line_data_tab(i).schedule_ship_date
      AND    xsrv.end_date_active    >= gt_ship_line_data_tab(i).schedule_ship_date
      ;
--
      -- �v�揤�i����������ꍇ�̂�
      IF ( ln_plan_item_cnt >= cn_1 ) THEN
        -- 9-2-4.�o�א�����(����v��)
        xxwsh_common910_pkg.check_shipping_judgment(
           iv_check_class      =>  cv_check_class_4                                     -- �`�F�b�N���@(�o�א�����(����v�揤�i))
          ,iv_base_cd          =>  gt_ship_line_data_tab(i).head_sales_branch           -- �Ǌ����_
          ,in_item_id          =>  gt_ship_line_data_tab(i).shipping_inventory_item_id  -- �o�וi��ID
          ,in_amount           =>  gt_ship_line_data_tab(i).quantity                    -- ���ׂ̑���
          ,id_date             =>  gt_ship_line_data_tab(i).schedule_ship_date          -- �o�ח\���
          ,in_deliver_from_id  =>  gt_ship_line_data_tab(i).deliver_from_id             -- �o�׌��ۊǏꏊID
          ,iv_request_no       =>  gt_ship_line_data_tab(i).request_no                  -- �˗�No
          ,ov_retcode          =>  lv_ret_code                                          -- ���^�[���R�[�h
          ,ov_errmsg_code      =>  lv_err_code                                          -- �G���[���b�Z�[�W�R�[�h
          ,ov_errmsg           =>  lv_err_msg                                           -- �G���[���b�Z�[�W
          ,on_result           =>  ln_result                                            -- ��������
        );
        -- ���^�[���R�[�h������łȂ��ꍇ
        IF ( lv_ret_code <> cv_status_normal ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh                                                       -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxwsh_13248                                                       -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_chk_type                                                          -- �g�[�N���R�[�h1
                         ,iv_token_value1  =>  cv_msg_xxwsh_13237                                                       -- �g�[�N���l1
                         ,iv_token_name2   =>  cv_tkn_request_no                                                        -- �g�[�N���R�[�h2
                         ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                      -- �g�[�N���l2
                         ,iv_token_name3   =>  cv_tkn_item_code                                                         -- �g�[�N���R�[�h3
                         ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- �g�[�N���l3
                         ,iv_token_name4   =>  cv_tkn_hs_branch                                                         -- �g�[�N���R�[�h4
                         ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- �g�[�N���l4
                         ,iv_token_name5   =>  cv_tkn_quantity                                                          -- �g�[�N���R�[�h5
                         ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                             -- �g�[�N���l5
                         ,iv_token_name6   =>  cv_tkn_base_date                                                         -- �g�[�N���R�[�h6
                         ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- �g�[�N���l6
                         ,iv_token_name7   =>  cv_tkn_deliver_from                                                      -- �g�[�N���R�[�h7
                         ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                    -- �g�[�N���l7
                         ,iv_token_name8   =>  cv_tkn_input_line_no                                                     -- �g�[�N���R�[�h8
                         ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                     -- �g�[�N���l8
                         ,iv_token_name9   =>  cv_tkn_err_msg                                                           -- �g�[�N���R�[�h9
                         ,iv_token_value9  =>  lv_err_msg                                                               -- �g�[�N���l9
                        );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂Ă�
          lv_err_flag := cv_yes;
        -- �������ʂ�����łȂ��ꍇ
        ELSIF ( ln_result <> cn_ret_normal) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh                                                       -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxwsh_13236                                                       -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_chk_type                                                          -- �g�[�N���R�[�h1
                         ,iv_token_value1  =>  cv_msg_xxwsh_13237                                                       -- �g�[�N���l1
                         ,iv_token_name2   =>  cv_tkn_request_no                                                        -- �g�[�N���R�[�h2
                         ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                      -- �g�[�N���l2
                         ,iv_token_name3   =>  cv_tkn_item_code                                                         -- �g�[�N���R�[�h3
                         ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- �g�[�N���l3
                         ,iv_token_name4   =>  cv_tkn_hs_branch                                                         -- �g�[�N���R�[�h4
                         ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- �g�[�N���l4
                         ,iv_token_name5   =>  cv_tkn_quantity                                                          -- �g�[�N���R�[�h5
                         ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                             -- �g�[�N���l5
                         ,iv_token_name6   =>  cv_tkn_base_date                                                         -- �g�[�N���R�[�h6
                         ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- �g�[�N���l6
                         ,iv_token_name7   =>  cv_tkn_deliver_from                                                      -- �g�[�N���R�[�h7
                         ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                    -- �g�[�N���l7
                         ,iv_token_name8   =>  cv_tkn_input_line_no                                                     -- �g�[�N���R�[�h8
                         ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                     -- �g�[�N���l8
                        );
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �G���[�t���O�𗧂Ă�
          lv_err_flag := cv_yes;
        END IF;
      END IF;
--
    END LOOP chk_emp_of_logi;
--
    -- �����S���p�̑Ó����`�F�b�N�ŃG���[������ꍇ���x���Ƃ���
    IF ( lv_err_flag = cv_yes ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_work_cur%ISOPEN ) THEN
        CLOSE get_work_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ship_request_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_order_data
   * Description      : �󒍃A�h�I���X�V (M-4)
   ***********************************************************************************/
  PROCEDURE upd_order_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_order_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J�����[�U�[��`��O ***
    data_skip_expt EXCEPTION;      -- �X�L�b�v�f�[�^��O
--
    -- *** ���[�J���ϐ� ***
    lv_dummy                     VARCHAR2(1);                                             -- �_�~�[(���b�N�p)
    ln_suc_line_cnt              NUMBER;                                                  -- ���גP�ʐ�������
    -- �󒍃A�h�I���w�b�_�ւ̓o�^�p
    lt_sum_quantity              xxwsh_order_headers_all.sum_quantity%TYPE;               -- ���v����
    lt_small_quantity            xxwsh_order_headers_all.small_quantity%TYPE;             -- ������
    lt_label_quantity            xxwsh_order_headers_all.label_quantity%TYPE;             -- ���x������
    lt_shipping_method_code      xxwsh_order_headers_all.shipping_method_code%TYPE;       -- �z���敪
    lt_based_weight              xxwsh_order_headers_all.based_weight%TYPE;               -- ��{�d��
    lt_loading_efficiency_weight xxwsh_order_headers_all.loading_efficiency_weight%TYPE;  -- �d�ʐύڌ���
    lt_sum_weight                xxwsh_order_headers_all.sum_weight%TYPE;                 -- �ύڏd�ʍ��v
    lt_sum_capacity              xxwsh_order_headers_all.sum_capacity%TYPE;               -- �ύڗe�ύ��v
    lt_sum_pallet_weight         xxwsh_order_headers_all.sum_pallet_weight%TYPE;          -- ���v�p���b�g�d��
    lt_pallet_sum_quantity       xxwsh_order_headers_all.pallet_sum_quantity%TYPE;        -- �p���b�g���v����
    -- ���ʊ֐��E�v�Z�p
    lv_ret_code                  VARCHAR2(1);                                             -- ���^�[���R�[�h(���ʊ֐��p)
    lv_err_msg_code              VARCHAR2(4000);                                          -- �G���[���b�Z�[�W�R�[�h(���ʊ֐��p)
    lv_err_msg                   VARCHAR2(5000);                                          -- �G���[���b�Z�[�W(���ʊ֐��p)
    ln_ship_cnv_quantity         NUMBER;                                                  -- �o�גP�ʊ��Z��(�������v�Z�p)
    ln_weight                    NUMBER;                                                  -- �d�ʍ��v(�ύڏd�ʍ��v�v�Z�p)
    ln_l_e_weight_calc           NUMBER;                                                  -- �d�ʍ��v(�d�ʐύڌ����擾�p)
    lt_max_ship_methods          xxcmn_ship_methods.ship_method%TYPE;                     -- �ő�z���敪(�z���敪�擾�p)
    lt_drink_deadweight          xxcmn_ship_methods.drink_deadweight%TYPE;                -- �h�����N�ύڏd��(��{�d�ʌv�Z�p)
    lt_palette_max_qty           xxcmn_ship_methods.palette_max_qty%TYPE;                 -- �p���b�g�ő喇��(�`�F�b�N�p)
    lv_loading_over_class        VARCHAR2(1);                                             -- �ύڃI�[�o�[�敪(�`�F�b�N�p)
    -- ���ʊ֐��p(�_�~�[)
    lv_ship_m_dummy              xxcmn_ship_methods.ship_method%TYPE;                     -- �o�ו��@
    lt_drink_d_dummy             xxcmn_ship_methods.drink_deadweight%TYPE;                -- �h�����N�ύڏd��
    lt_leaf_d_dummy              xxcmn_ship_methods.leaf_deadweight%TYPE;                 -- ���[�t�ύڏd��
    lt_drink_c_dummy             xxcmn_ship_methods.drink_loading_capacity%TYPE;          -- �h�����N�ύڗe��
    lt_leaf_c_dummy              xxcmn_ship_methods.leaf_loading_capacity%TYPE;           -- ���[�t�ύڗe��
    lt_palette_m_q_dummy         xxcmn_ship_methods.palette_max_qty%TYPE;                 -- �p���b�g�ő喇��
    lv_mixed_ship_m_dummy        VARCHAR2(256);                                           -- ���ڔz���敪
    ln_efficiency_w_dummy        NUMBER;                                                  -- �d�ʐύڌ���
    ln_efficiency_c_dummy        NUMBER;                                                  -- �e�ϐύڌ���
    -- ����No�`�F�b�N�p
    lt_based_w_mixed             xxwsh_order_headers_all.based_weight%TYPE;               -- ��{�d��(�����)
    lt_sum_w_mixed               xxwsh_order_headers_all.sum_weight%TYPE;                 -- �ύڏd�ʍ��v(�����)
    lt_sum_pallet_w_mixed        xxwsh_order_headers_all.sum_pallet_weight%TYPE;          -- ���v�p���b�g�d��(�����)
    lt_small_amount_c_mixed      xxwsh_ship_method_v.small_amount_class%TYPE;             -- �����敪(�����)
    ln_w_mixed_sum               NUMBER;                                                  -- �ύڏd�ʍ��v(����No�P��)
    ln_p_mixed_sum               NUMBER;                                                  -- ���v�p���b�g�d��(����No�P��)
    ln_chk_w_mixed_sum           NUMBER;                                                  -- �ύڏd�ʍ��v(�v�Z�p)
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �o�׈˗��擾�p�J�[�\��
    CURSOR get_ship_date_cur(
      it_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE
    )
    IS
      SELECT  xoha.order_header_id        order_header_id        -- �󒍃w�b�_�A�h�I��ID
             ,xoha.request_no             request_no             -- �˗�No
             ,xoha.freight_charge_class   freight_charge_class   -- �^���敪
             ,xoha.deliver_from           deliver_from           -- �o�׌��ۊǏꏊ
             ,xoha.deliver_to             deliver_to             -- �o�א�
             ,xoha.prod_class             prod_class             -- ���i�敪
             ,xoha.weight_capacity_class  weight_capacity_class  -- �d�ʗe�ϋ敪
             ,xoha.shipping_method_code   shipping_method_code   -- �z���敪
             ,xoha.based_weight           based_weight           -- ��{�d��
             ,xola.quantity               quantity               -- ����
             ,xola.weight                 weight                 -- �d��
             ,xola.capacity               capacity               -- �e��
             ,xola.pallet_qty             pallet_qty             -- �p���b�g����
             ,xola.pallet_weight          pallet_weight          -- �p���b�g�d��
             ,ximv.num_of_cases           num_of_cases           -- �P�[�X����
             ,ximv.num_of_deliver         num_of_deliver         -- �o�ד���
             ,xsmv.small_amount_class     small_amount_class     -- �����敪
       FROM   xxwsh_order_headers_all xoha  -- �󒍃w�b�_�A�h�I��
             ,xxwsh_order_lines_all   xola  -- �󒍖��׃A�h�I��
             ,xxcmn_item_mst2_v       ximv  -- OPM�i�ڏ��VIEW2
             ,xxwsh_ship_method2_v    xsmv  -- �z���敪���VIEW2
      WHERE   xoha.order_header_id           = it_order_header_id
      AND     xoha.order_header_id           = xola.order_header_id
      AND     NVL( xola.delete_flag, cv_no ) = cv_no
      AND     xola.request_item_code         = ximv.item_no
      AND     ximv.start_date_active        <= cd_sysdate
      AND     ximv.end_date_active          >= cd_sysdate
      AND     xoha.shipping_method_code      = xsmv.ship_method_code(+)
      AND     xsmv.start_date_active(+)     <= xoha.schedule_ship_date
      AND     NVL( xsmv.end_date_active(+), xoha.schedule_ship_date )
                                            >= xoha.schedule_ship_date
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_ship_date_rec  get_ship_date_cur%ROWTYPE;  -- �J�[�\���f�[�^���R�[�h
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    -- ���׌����̏�����
    ln_suc_line_cnt   := 0;
    --==============================================================
    -- M-4.1 �z��̃f�[�^�̎擾
    --==============================================================
    <<upd_data_loop>>
    FOR i IN 1..gt_ship_line_data_tab.COUNT LOOP
--
      -- ������
      lv_ret_code     := cv_status_normal;
      lv_dummy        := NULL;
      lv_err_msg      := NULL;
      -- ���׌����J�E���g
      ln_suc_line_cnt := ln_suc_line_cnt + 1;
--
      -- �Z�[�u�|�C���g�̔��s
      SAVEPOINT req_unit_save;
--
      BEGIN
--
        --==============================================================
        -- M-4.2 �󒍖��׃A�h�I���̃��b�N
        --==============================================================
        BEGIN
          SELECT cv_yes  lock_ok
          INTO   lv_dummy
          FROM   xxwsh_order_lines_all xola
          WHERE  xola.rowid = gt_ship_line_data_tab(i).xola_rowid
          FOR UPDATE OF
                 xola.order_line_id
          NOWAIT
          ;
        EXCEPTION
          WHEN  global_lock_expt THEN
            -- ���b�Z�[�W�ҏW
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh                            -- �A�v���P�[�V�����Z�k��
                           ,iv_name          =>  cv_msg_xxwsh_13214                            -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   =>  cv_tkn_table                                  -- �g�[�N���R�[�h1
                           ,iv_token_value1  =>  cv_msg_xxwsh_13249                            -- �g�[�N���l1
                           ,iv_token_name2   =>  cv_tkn_request_no                             -- �g�[�N���R�[�h2
                           ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no           -- �g�[�N���l2
                           ,iv_token_name3   =>  cv_tkn_item_code                              -- �g�[�N���R�[�h3
                           ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code   -- �g�[�N���l3
                           ,iv_token_name4   =>  cv_tkn_input_line_no                          -- �g�[�N���R�[�h4
                           ,iv_token_value4  =>  gt_ship_line_data_tab(i).line_number          -- �g�[�N���l4
                          );
            RAISE data_skip_expt;
        END;
--
        -- ���������ς݂̏ꍇ�̂�
        IF ( gt_ship_line_data_tab(i).automanual_reserve_class  = cv_reserve_flag_auto ) THEN
          --=============================================================================
          -- M-4.3 ���ʊ֐��u���������֐��v�ɂ�薾�ׂ̈���������
          --=============================================================================
          lv_ret_code := xxwsh_common_pkg.cancel_reserve(
                            iv_biz_type    => cv_ship                                 -- �Ɩ���ʁF1(�o��)
                           ,iv_request_no  => gt_ship_line_data_tab(i).request_no     -- �˗�No
                           ,in_line_id     => gt_ship_line_data_tab(i).order_line_id  -- ����ID
                           ,ov_errmsg      => lv_err_msg                              -- �G���[���b�Z�[�W
                         );
          -- ���^�[���R�[�h������łȂ��ꍇ
          IF ( lv_ret_code <> cv_status_normal ) THEN
            -- ���b�Z�[�W�ҏW
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh                            -- �A�v���P�[�V�����Z�k��
                           ,iv_name          =>  cv_msg_xxwsh_13216                            -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   =>  cv_tkn_request_no                             -- �g�[�N���R�[�h1
                           ,iv_token_value1  =>  gt_ship_line_data_tab(i).request_no           -- �g�[�N���l1
                           ,iv_token_name2   =>  cv_tkn_item_code                              -- �g�[�N���R�[�h2
                           ,iv_token_value2  =>  gt_ship_line_data_tab(i).shipping_item_code   -- �g�[�N���l2
                           ,iv_token_name3   =>  cv_tkn_input_line_no                          -- �g�[�N���R�[�h3
                           ,iv_token_value3  =>  gt_ship_line_data_tab(i).line_number          -- �g�[�N���l3
                           ,iv_token_name4   =>  cv_tkn_err_msg                                -- �g�[�N���R�[�h4
                           ,iv_token_value4  =>  lv_err_msg                                    -- �g�[�N���l4
                          );
            RAISE data_skip_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- M-4.4 �󒍖��׃A�h�I���̍X�V
        --==============================================================
        BEGIN
          UPDATE  xxwsh_order_lines_all xola
          SET     xola.shipping_inventory_item_id  = gt_ship_line_data_tab(i).shipping_inventory_item_id
                 ,xola.shipping_item_code          = gt_ship_line_data_tab(i).shipping_item_code
                 ,xola.quantity                    = gt_ship_line_data_tab(i).quantity
                 ,xola.uom_code                    = gt_ship_line_data_tab(i).uom_code
                 ,xola.shipped_quantity            = gt_ship_line_data_tab(i).shipped_quantity
                 ,xola.based_request_quantity      = gt_ship_line_data_tab(i).based_request_quantity
                 ,xola.request_item_id             = gt_ship_line_data_tab(i).request_item_id
                 ,xola.request_item_code           = gt_ship_line_data_tab(i).request_item_code
                 ,xola.po_number                   = gt_ship_line_data_tab(i).po_number
                 ,xola.pallet_quantity             = gt_ship_line_data_tab(i).pallet_quantity
                 ,xola.layer_quantity              = gt_ship_line_data_tab(i).layer_quantity
                 ,xola.case_quantity               = gt_ship_line_data_tab(i).case_quantity
                 ,xola.weight                      = gt_ship_line_data_tab(i).weight
                 ,xola.capacity                    = gt_ship_line_data_tab(i).capacity
                 ,xola.pallet_qty                  = gt_ship_line_data_tab(i).pallet_qty
                 ,xola.pallet_weight               = gt_ship_line_data_tab(i).pallet_weight
                 ,xola.shipping_request_if_flg     = gt_ship_line_data_tab(i).shipping_request_if_flg
                 ,xola.shipping_result_if_flg      = gt_ship_line_data_tab(i).shipping_result_if_flg
                 ,xola.last_updated_by             = gt_ship_line_data_tab(i).last_updated_by
                 ,xola.last_update_date            = gt_ship_line_data_tab(i).last_update_date
                 ,xola.last_update_login           = gt_ship_line_data_tab(i).last_update_login
                 ,xola.request_id                  = gt_ship_line_data_tab(i).request_id
                 ,xola.program_application_id      = gt_ship_line_data_tab(i).program_application_id
                 ,xola.program_id                  = gt_ship_line_data_tab(i).program_id
                 ,xola.program_update_date         = gt_ship_line_data_tab(i).program_update_date
          WHERE   xola.rowid                       = gt_ship_line_data_tab(i).xola_rowid
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- ���b�Z�[�W�ҏW
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh                            -- �A�v���P�[�V�����Z�k��
                           ,iv_name          =>  cv_msg_xxwsh_13215                            -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   =>  cv_tkn_table                                  -- �g�[�N���R�[�h1
                           ,iv_token_value1  =>  cv_msg_xxwsh_13249                            -- �g�[�N���l1
                           ,iv_token_name2   =>  cv_tkn_request_no                             -- �g�[�N���R�[�h2
                           ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no           -- �g�[�N���l2
                           ,iv_token_name3   =>  cv_tkn_item_code                              -- �g�[�N���R�[�h3
                           ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code   -- �g�[�N���l3
                           ,iv_token_name4   =>  cv_tkn_input_line_no                          -- �g�[�N���R�[�h4
                           ,iv_token_value4  =>  gt_ship_line_data_tab(i).line_number          -- �g�[�N���l4
                           ,iv_token_name5   =>  cv_tkn_err_msg                                -- �g�[�N���R�[�h5
                           ,iv_token_value5  =>  SQLERRM                                       -- �g�[�N���l5
                          );
            RAISE data_skip_expt;
        END;
--
        --==============================================================
        -- M-4.5 �w�b�_���ڂ̍Čv�Z�E�Ó����`�F�b�N�E�X�V(�w�b�_�u���[�N����)
        --==============================================================
        -- �w�b�_ID�������R�[�h�����݂����قȂ�A�������͍ŏI���R�[�h�̏ꍇ(����˗��̍ŏI�f�[�^�̏ꍇ)
        IF (
             (
                ( gt_ship_line_data_tab.EXISTS(i+1) )
                AND
                ( gt_ship_line_data_tab(i).order_header_id <> gt_ship_line_data_tab(i+1).order_header_id )
             )
             OR
             ( NOT gt_ship_line_data_tab.EXISTS(i+1) )
           ) THEN
--
           -- ������
           lt_sum_quantity           := 0;  -- ���v����
           ln_ship_cnv_quantity      := 0;  -- �o�גP�ʊ��Z��
           lt_small_quantity         := 0;  -- ������
           lt_label_quantity         := 0;  -- ���x������
           lt_sum_weight             := 0;  -- �ύڏd�ʍ��v
           ln_weight                 := 0;  -- �ύڏd�ʍ��v�v�Z�p
           ln_l_e_weight_calc        := 0;  -- �d�ʐύڌ����擾�p
           lt_sum_capacity           := 0;  -- �ύڗe�ύ��v
           lt_sum_pallet_weight      := 0;  -- ���v�p���b�g�d��
           lt_pallet_sum_quantity    := 0;  -- ���v�p���b�g����
--
           -- 5-1.�󒍏��𒊏o
           OPEN  get_ship_date_cur(
                   gt_ship_line_data_tab(i).order_header_id
                 );
           <<get_ship_data_loop>>
           LOOP
--
             FETCH get_ship_date_cur INTO l_get_ship_date_rec;
             EXIT WHEN get_ship_date_cur%NOTFOUND;
--
             -- 5-2.���v���ʂ̌v�Z
             lt_sum_quantity := lt_sum_quantity + l_get_ship_date_rec.quantity;
--
             -- 5-3.�������̌v�Z
--
             -- �o�ד����ɒl������ꍇ
             IF ( l_get_ship_date_rec.num_of_deliver IS NOT NULL )THEN
               -- �o�ד��� > 0 �̏ꍇ
               IF ( l_get_ship_date_rec.num_of_deliver > cn_0 ) THEN
                 -- �o�גP�ʊ��Z��(���ʁ��o�ד���)
                 ln_ship_cnv_quantity := l_get_ship_date_rec.quantity / l_get_ship_date_rec.num_of_deliver;
               ELSE
                 -- �o�גP�ʊ��Z��(0)
                 ln_ship_cnv_quantity := 0;
               END IF;
             -- �P�[�X�����ɒl������ꍇ
             ELSIF ( l_get_ship_date_rec.num_of_cases IS NOT NULL ) THEN
              -- �P�[�X���� > 0 �̏ꍇ
               IF ( l_get_ship_date_rec.num_of_cases > cn_0 ) THEN
                 -- �o�גP�ʊ��Z��(���ʁ��P�[�X����)
                 ln_ship_cnv_quantity := l_get_ship_date_rec.quantity / l_get_ship_date_rec.num_of_cases;
               ELSE
                 -- �o�גP�ʊ��Z��(0)
                 ln_ship_cnv_quantity := 0;
               END IF;
             -- ��L�ȊO(����)
             ELSE
               ln_ship_cnv_quantity := l_get_ship_date_rec.quantity;
             END IF;
--
             -- ������(�����_�ȉ��؏グ)
             lt_small_quantity := lt_small_quantity + TRUNC( ln_ship_cnv_quantity + 0.9 );
--
             -- 5-4.���x�������̌v�Z
             lt_label_quantity := lt_label_quantity + TRUNC( ln_ship_cnv_quantity + 0.9 );
--
             -- �����敪��1(����)�̏ꍇ(�d�ʍ��v)
             IF ( l_get_ship_date_rec.small_amount_class = cv_amount_class_small ) THEN
               -- �d�ʍ��v(�d�ʍ��v)
               ln_weight := l_get_ship_date_rec.weight;
             -- �����敪��1(����)�ȊO�̏ꍇ
             ELSE
               -- �d�ʍ��v(�d�ʍ��v+�p���b�g�d��)
               ln_weight := l_get_ship_date_rec.weight + l_get_ship_date_rec.pallet_weight;
             END IF;
             -- 5-5.�d�ʐύڌ����擾�p�̏d�ʂ̌v�Z
             ln_l_e_weight_calc := ln_l_e_weight_calc + ln_weight;
--
             -- 5-6.���v�d�ʂ̌v�Z
             lt_sum_weight   := lt_sum_weight + l_get_ship_date_rec.weight;
--
             -- 5-7.���v�e�ς̌v�Z
             lt_sum_capacity := lt_sum_capacity + l_get_ship_date_rec.capacity;
--
             -- 5-8.���v�p���b�g�d��
             lt_sum_pallet_weight := lt_sum_pallet_weight + l_get_ship_date_rec.pallet_weight;
--
             -- 5-9.�p���b�g���v����
             lt_pallet_sum_quantity := lt_pallet_sum_quantity + l_get_ship_date_rec.pallet_qty;
--
           END LOOP get_ship_data_loop;
--
           -- �J�[�\���N���[�Y
           CLOSE get_ship_date_cur;
--
           lt_max_ship_methods       := NULL;             -- �ő�z���敪
           lt_drink_deadweight       := 0;                -- �h�����N�ύڏd��
           lt_palette_max_qty        := 0;                -- �p���b�g�ő喇��
           lv_loading_over_class     := 0;                -- �ύڃI�[�o�[�敪
--
           -- 5-10.�p���b�g�ő喇�����߃`�F�b�N�Ɛύڌ����`�F�b�N(�^���敪��ON�̏ꍇ�̂�)
           IF ( l_get_ship_date_rec.freight_charge_class = cv_freight_charge_on ) THEN
--
             -- ������
             lv_ret_code := cv_status_normal;
--
             -- 5-10-1. ���ʊ֐��u�ő�z���敪�Z�o�֐��v���ő�z���敪���擾
             lv_ret_code := xxwsh_common_pkg.get_max_ship_method(
                              iv_code_class1                 => cv_code_class_4                            -- 4(�q��)
                             ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from           -- �o�׌��ۊǏꏊ
                             ,iv_code_class2                 => cv_code_class_9                            -- 9(�z����)
                             ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to             -- �o�א�
                             ,iv_prod_class                  => l_get_ship_date_rec.prod_class             -- ���i�敪
                             ,iv_weight_capacity_class       => l_get_ship_date_rec.weight_capacity_class  -- �d�ʗe�ϋ敪
                             ,iv_auto_process_type           => NULL                                       -- NULL(�����z�ԑΏۋ敪)
                             ,id_standard_date               => NULL                                       -- NULL(���)
                             ,ov_max_ship_methods            => lt_max_ship_methods                        -- �ő�z���敪
                             ,on_drink_deadweight            => lt_drink_deadweight                        -- �h�����N�ύڏd��
                             ,on_leaf_deadweight             => lt_leaf_d_dummy                            -- ���[�t�ύڏd��
                             ,on_drink_loading_capacity      => lt_drink_c_dummy                           -- �h�����N�ύڗe��
                             ,on_leaf_loading_capacity       => lt_leaf_c_dummy                            -- ���[�t�ύڗe��
                             ,on_palette_max_qty             => lt_palette_m_q_dummy                       -- �p���b�g�ő喇��
                            );
             IF ( lv_ret_code <> cv_status_normal ) THEN
               -- ���b�Z�[�W�ҏW
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                         -- �A�v���P�[�V�����Z�k��
                              ,iv_name          =>  cv_msg_xxwsh_13217                         -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1   =>  cv_tkn_request_no                          -- �g�[�N���R�[�h1
                              ,iv_token_value1  =>  l_get_ship_date_rec.request_no             -- �g�[�N���l1
                              ,iv_token_name2   =>  cv_tkn_deliver_from                        -- �g�[�N���R�[�h2
                              ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from           -- �g�[�N���l2
                              ,iv_token_name3   =>  cv_tkn_deliver_to                          -- �g�[�N���R�[�h3
                              ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to             -- �g�[�N���l3
                              ,iv_token_name4   =>  cv_tkn_prod_class                          -- �g�[�N���R�[�h4
                              ,iv_token_value4  =>  l_get_ship_date_rec.prod_class             -- �g�[�N���l4
                              ,iv_token_name5   =>  cv_tkn_weight_class                        -- �g�[�N���R�[�h5
                              ,iv_token_value5  =>  l_get_ship_date_rec.weight_capacity_class  -- �g�[�N���l5
                              ,iv_token_name6   =>  cv_tkn_err_code                            -- �g�[�N���R�[�h6
                              ,iv_token_value6  =>  lv_ret_code                                -- �g�[�N���l6
                             );
               RAISE data_skip_expt;
             END IF;
--
             -- ������
             lv_ret_code := cv_status_normal;
--
             -- 5-10-2.���ʊ֐��u�p���b�g�ő喇�����߃`�F�b�N�v�ɂ��p���b�g�ő喇���̃`�F�b�N�����{(�����S���ׁ̈A���b�Z�[�W�̏o�͂̂�)
             lv_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                              iv_code_class1                 => cv_code_class_4                   -- 4(�q��)
                             ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from  -- �o�׌��ۊǏꏊ
                             ,iv_code_class2                 => cv_code_class_9                   -- 9(�z����)
                             ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to    -- �o�א�
                             ,id_standard_date               => NULL                              -- NULL(���)
                             ,iv_ship_methods                => lt_max_ship_methods               -- �ő�z���敪
                             ,on_drink_deadweight            => lt_drink_d_dummy                  -- �h�����N�ύڏd��
                             ,on_leaf_deadweight             => lt_leaf_d_dummy                   -- ���[�t�ύڏd��
                             ,on_drink_loading_capacity      => lt_drink_c_dummy                  -- �h�����N�ύڗe��
                             ,on_leaf_loading_capacity       => lt_leaf_c_dummy                   -- ���[�t�ύڗe��
                             ,on_palette_max_qty             => lt_palette_max_qty                -- �p���b�g�ő喇��
                            );
             -- �p���b�g�ő喇�� < �p���b�g���v�����̏ꍇ
             IF ( lt_palette_max_qty < lt_pallet_sum_quantity ) THEN
               -- ���b�Z�[�W�ҏW
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                         -- �A�v���P�[�V�����Z�k��
                              ,iv_name          =>  cv_msg_xxwsh_13239                         -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1   =>  cv_tkn_request_no                          -- �g�[�N���R�[�h1
                              ,iv_token_value1  =>  l_get_ship_date_rec.request_no             -- �g�[�N���l1
                              ,iv_token_name2   =>  cv_tkn_deliver_from                        -- �g�[�N���R�[�h2
                              ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from           -- �g�[�N���l2
                              ,iv_token_name3   =>  cv_tkn_deliver_to                          -- �g�[�N���R�[�h3
                              ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to             -- �g�[�N���l3
                              ,iv_token_name4   =>  cv_tkn_s_method_code                       -- �g�[�N���R�[�h4
                              ,iv_token_value4  =>  lt_max_ship_methods                        -- �g�[�N���l4
                             );
               -- �o�͂ɕ\��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               -- ���O�ɕ\��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.LOG
                 ,buff   => lv_errmsg
               );
               -- �������x���Ƃ���
               ov_retcode      := cv_status_warn;
             END IF;
--
             -- ������
             lv_ret_code      := cv_status_normal;
             lv_err_msg_code  := NULL;
             lv_err_msg       := NULL;
--
             -- 5-10-3.���ʊ֐��u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�ɂ��ύڌ����`�F�b�N�����{(�o�׈˗��̔z���敪�Ń`�F�b�N)
             xxwsh_common910_pkg.calc_load_efficiency(
               in_sum_weight                  => ln_l_e_weight_calc                         -- �d�ʐύڌ����擾�p�̍��v�d��(5-5)
              ,in_sum_capacity                => NULL                                       -- NULL(���v�e��)
              ,iv_code_class1                 => cv_code_class_4                            -- 4(�q��)
              ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from           -- �o�׌��ۊǏꏊ
              ,iv_code_class2                 => cv_code_class_9                            -- 9(�z����)
              ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to             -- �o�א�
              ,iv_ship_method                 => l_get_ship_date_rec.shipping_method_code   -- �z���敪(��)
              ,iv_prod_class                  => l_get_ship_date_rec.prod_class             -- ���i�敪
              ,iv_auto_process_type           => NULL                                       -- NULL(�����z�ԑΏۋ敪)
              ,id_standard_date               => cd_sysdate                                 -- �V�X�e�����t(���)
              ,ov_retcode                     => lv_ret_code                                -- ���^�[���E�R�[�h
              ,ov_errmsg_code                 => lv_err_msg_code                            -- �G���[���b�Z�[�W�R�[�h
              ,ov_errmsg                      => lv_err_msg                                 -- �G���[���b�Z�[�W
              ,ov_loading_over_class          => lv_loading_over_class                      -- �ύڃI�[�o�[�敪
              ,ov_ship_methods                => lv_ship_m_dummy                            -- �o�ו��@
              ,on_load_efficiency_weight      => lt_loading_efficiency_weight               -- �d�ʐύڌ���
              ,on_load_efficiency_capacity    => ln_efficiency_c_dummy                      -- �e�ϐύڌ���
              ,ov_mixed_ship_method           => lv_mixed_ship_m_dummy                      -- ���ڔz���敪
             );
             IF ( lv_ret_code <> cv_status_normal ) THEN
               -- ���b�Z�[�W�ҏW
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                       -- �A�v���P�[�V�����Z�k��
                              ,iv_name          =>  cv_msg_xxwsh_13218                       -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1   =>  cv_tkn_request_no                        -- �g�[�N���R�[�h1
                              ,iv_token_value1  =>  l_get_ship_date_rec.request_no           -- �g�[�N���l1
                              ,iv_token_name2   =>  cv_tkn_deliver_from                      -- �g�[�N���R�[�h2
                              ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from         -- �g�[�N���l2
                              ,iv_token_name3   =>  cv_tkn_deliver_to                        -- �g�[�N���R�[�h3
                              ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to           -- �g�[�N���l3
                              ,iv_token_name4   =>  cv_tkn_prod_class                        -- �g�[�N���R�[�h4
                              ,iv_token_value4  =>  l_get_ship_date_rec.prod_class           -- �g�[�N���l4
                              ,iv_token_name5   =>  cv_tkn_s_method_code                     -- �g�[�N���R�[�h5
                              ,iv_token_value5  =>  l_get_ship_date_rec.shipping_method_code -- �g�[�N���l5
                              ,iv_token_name6   =>  cv_tkn_base_date                         -- �g�[�N���R�[�h6
                              ,iv_token_value6  =>  TO_CHAR(cd_sysdate, cv_yyyymmdd_sla )    -- �g�[�N���l6
                              ,iv_token_name7   =>  cv_tkn_err_msg                           -- �g�[�N���R�[�h7
                              ,iv_token_value7  =>  lv_err_msg                               -- �g�[�N���l7
                             );
               RAISE data_skip_expt;
             END IF;
--
             -- �ύڌ������I�[�o�[���Ă��Ȃ��ꍇ
             IF ( lv_loading_over_class <> cv_loading_over ) THEN
               -- �d�ʐύڌ���
               lt_loading_efficiency_weight := lt_loading_efficiency_weight;             -- ��L�擾�����d�ʐύڌ���
               -- �z���敪
               lt_shipping_method_code      := l_get_ship_date_rec.shipping_method_code; -- �󒍂̔z���敪
               -- ��{�d��
               lt_based_weight              := l_get_ship_date_rec.based_weight;         -- �󒍂̊�{�d��
             -- �ύڌ������I�[�o�[���Ă���ꍇ
             ELSE
--
               -- ������
               lv_ret_code      := cv_status_normal;
               lv_err_msg_code  := NULL;
               lv_err_msg       := NULL;
--
                -- 5-10-4.���ʊ֐��u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�ɂ��ύڌ����`�F�b�N�����{(�ő�̔z���敪�Ń`�F�b�N)
               xxwsh_common910_pkg.calc_load_efficiency(
                 in_sum_weight                  => ln_l_e_weight_calc                         -- �d�ʐύڌ����擾�p�̍��v�d��(5-5)
                ,in_sum_capacity                => NULL                                       -- NULL(���v�e��)
                ,iv_code_class1                 => cv_code_class_4                            -- 4(�q��)
                ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from           -- �o�׌��ۊǏꏊ
                ,iv_code_class2                 => cv_code_class_9                            -- 9(�z����)
                ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to             -- �o�א�
                ,iv_ship_method                 => lt_max_ship_methods                        -- �z���敪(�ő�z���敪)
                ,iv_prod_class                  => l_get_ship_date_rec.prod_class             -- ���i�敪
                ,iv_auto_process_type           => NULL                                       -- NULL(�����z�ԑΏۋ敪)
                ,id_standard_date               => cd_sysdate                                 -- �V�X�e�����t(���)
                ,ov_retcode                     => lv_ret_code                                -- ���^�[���E�R�[�h
                ,ov_errmsg_code                 => lv_err_msg_code                            -- �G���[���b�Z�[�W�R�[�h
                ,ov_errmsg                      => lv_err_msg                                 -- �G���[���b�Z�[�W
                ,ov_loading_over_class          => lv_loading_over_class                      -- �ύڃI�[�o�[�敪
                ,ov_ship_methods                => lv_ship_m_dummy                            -- �o�ו��@
                ,on_load_efficiency_weight      => lt_loading_efficiency_weight               -- �d�ʐύڌ���
                ,on_load_efficiency_capacity    => ln_efficiency_c_dummy                      -- �e�ϐύڌ���
                ,ov_mixed_ship_method           => lv_mixed_ship_m_dummy                      -- ���ڔz���敪
               );
               IF ( lv_ret_code <> cv_status_normal ) THEN
                 -- ���b�Z�[�W�ҏW
                 lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application   =>  cv_appl_name_xxwsh                       -- �A�v���P�[�V�����Z�k��
                                ,iv_name          =>  cv_msg_xxwsh_13218                       -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1   =>  cv_tkn_request_no                        -- �g�[�N���R�[�h1
                                ,iv_token_value1  =>  l_get_ship_date_rec.request_no           -- �g�[�N���l1
                                ,iv_token_name2   =>  cv_tkn_deliver_from                      -- �g�[�N���R�[�h2
                                ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from         -- �g�[�N���l2
                                ,iv_token_name3   =>  cv_tkn_deliver_to                        -- �g�[�N���R�[�h3
                                ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to           -- �g�[�N���l3
                                ,iv_token_name4   =>  cv_tkn_prod_class                        -- �g�[�N���R�[�h4
                                ,iv_token_value4  =>  l_get_ship_date_rec.prod_class           -- �g�[�N���l4
                                ,iv_token_name5   =>  cv_tkn_s_method_code                     -- �g�[�N���R�[�h5
                                ,iv_token_value5  =>  lt_max_ship_methods                      -- �g�[�N���l5
                                ,iv_token_name6   =>  cv_tkn_base_date                         -- �g�[�N���R�[�h6
                                ,iv_token_value6  =>  TO_CHAR( cd_sysdate, cv_yyyymmdd_sla )   -- �g�[�N���l6
                                ,iv_token_name7   =>  cv_tkn_err_msg                           -- �g�[�N���R�[�h7
                                ,iv_token_value7  =>  lv_err_msg                               -- �g�[�N���l7
                               );
                 RAISE data_skip_expt;
               END IF;
               -- �ύڌ������I�[�o�[���Ă��Ȃ��ꍇ
               IF ( lv_loading_over_class <> cv_loading_over ) THEN
                 -- �d�ʐύڌ���
                 lt_loading_efficiency_weight := lt_loading_efficiency_weight;  -- ��L�擾�����d�ʐύڌ���
                 -- �z���敪
                 lt_shipping_method_code      := lt_max_ship_methods;           -- �ő�z���敪
                 -- ��{�d��
                 lt_based_weight              := lt_drink_deadweight;           -- �h�����N�ύڏd��(5-9-1)
               -- �ύڌ������I�[�o�[���Ă���ꍇ
               ELSE
                 -- ���b�Z�[�W�ҏW
                 lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                                ,iv_name          =>  cv_msg_xxwsh_13219              -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1   =>  cv_tkn_request_no               -- �g�[�N���R�[�h1
                                ,iv_token_value1  =>  l_get_ship_date_rec.request_no  -- �g�[�N���l1
                                ,iv_token_name2   =>  cv_tkn_weight                   -- �g�[�N���R�[�h2
                                ,iv_token_value2  =>  TO_CHAR( ln_l_e_weight_calc )   -- �g�[�N���l2
                               );
                 RAISE data_skip_expt;
               END IF;
             END IF;
           -- �^���敪��OFF�̏ꍇ
           ELSE
             -- �d�ʐύڌ���
             lt_loading_efficiency_weight := NULL;
             -- �z���敪
             lt_shipping_method_code      := NULL;
             -- ��{�d��
             lt_based_weight              := NULL;
           END IF;
--
           -- 5-11.�󒍃w�b�_�A�h�I���̃��b�N
           BEGIN
             SELECT cv_yes  lock_ok
             INTO   lv_dummy
             FROM   xxwsh_order_headers_all xoha
             WHERE  xoha.order_header_id = l_get_ship_date_rec.order_header_id
             FOR UPDATE OF
                    xoha.order_header_id
             NOWAIT
             ;
           EXCEPTION
             WHEN  global_lock_expt THEN
               -- ���b�Z�[�W�ҏW
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                              ,iv_name          =>  cv_msg_xxwsh_13220              -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1   =>  cv_tkn_table                    -- �g�[�N���R�[�h1
                              ,iv_token_value1  =>  cv_msg_xxwsh_13250              -- �g�[�N���l1
                              ,iv_token_name2   =>  cv_tkn_request_no               -- �g�[�N���R�[�h2
                              ,iv_token_value2  =>  l_get_ship_date_rec.request_no  -- �g�[�N���l2
                             );
               RAISE data_skip_expt;
           END;
--
           -- 5-12.�󒍃w�b�_�A�h�I�����X�V
           BEGIN
             UPDATE  xxwsh_order_headers_all xoha
             SET     xoha.sum_quantity              = lt_sum_quantity               -- ���v����
                    ,xoha.small_quantity            = lt_small_quantity             -- ������
                    ,xoha.label_quantity            = lt_label_quantity             -- ���x������
                    ,xoha.shipping_method_code      = lt_shipping_method_code       -- �z���敪
                    ,xoha.based_weight              = lt_based_weight               -- ��{�d��
                    ,xoha.loading_efficiency_weight = lt_loading_efficiency_weight  -- �d�ʐύڌ���
                    ,xoha.sum_weight                = lt_sum_weight                 -- �ύڏd�ʍ��v
                    ,xoha.sum_capacity              = lt_sum_capacity               -- �ύڗe�ύ��v
                    ,xoha.sum_pallet_weight         = lt_sum_pallet_weight          -- ���v�p���b�g�d��
                    ,xoha.pallet_sum_quantity       = lt_pallet_sum_quantity        -- �p���b�g���v����
                    ,xoha.screen_update_date        = cd_last_update_date           -- ��ʍX�V����
                    ,xoha.screen_update_by          = cn_last_updated_by            -- ��ʍX�V��
                    ,xoha.last_updated_by           = cn_last_updated_by            -- �ŏI�X�V��
                    ,xoha.last_update_date          = cd_last_update_date           -- �ŏI�X�V��
                    ,xoha.last_update_login         = cn_last_update_login          -- �ŏI�X�V���O�C��
                    ,xoha.request_id                = cn_request_id                 -- �v��ID
                    ,xoha.program_application_id    = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                    ,xoha.program_id                = cn_program_id                 -- �R���J�����g�E�v���O����ID
                    ,xoha.program_update_date       = cd_program_update_date        -- �v���O�����X�V��
             WHERE   xoha.order_header_id           = l_get_ship_date_rec.order_header_id
             ;
           EXCEPTION
             WHEN OTHERS THEN
               -- ���b�Z�[�W�ҏW
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                              ,iv_name          =>  cv_msg_xxwsh_13221              -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1   =>  cv_tkn_table                    -- �g�[�N���R�[�h1
                              ,iv_token_value1  =>  cv_msg_xxwsh_13250              -- �g�[�N���l1
                              ,iv_token_name2   =>  cv_tkn_request_no               -- �g�[�N���R�[�h2
                              ,iv_token_value2  =>  l_get_ship_date_rec.request_no  -- �g�[�N���l2
                              ,iv_token_name3   =>  cv_tkn_err_msg                  -- �g�[�N���R�[�h3
                              ,iv_token_value3  =>  SQLERRM                         -- �g�[�N���l3
                             );
               RAISE data_skip_expt;
           END;
--
           -- ������
           lv_ret_code      := cv_status_normal;
           lv_err_msg       := NULL;
--
           -- 5-13.���ʊ֐��u�z�ԉ����֐��v�ɂ��z�Ԃ̉������s���܂��B(�z�ԒP�ʂŏd�ʃI�[�o�[�̏ꍇ�̂݉���)
           lv_ret_code := xxwsh_common_pkg.cancel_careers_schedule(
                            iv_biz_type     => cv_ship                         -- 1(�o�׈˗�)
                           ,iv_request_no   => l_get_ship_date_rec.request_no  -- �˗�No
                           ,iv_calcel_flag  => cv_cancel_flag_judge            -- 2(�d�ʃI�[�o�[�̏ꍇ�̂ݔz�ԉ���)
                           ,ov_errmsg       => lv_err_msg                      -- �G���[���b�Z�[�W
                          );
           IF (  lv_ret_code <> cv_status_normal ) THEN
             -- ���b�Z�[�W�ҏW
             lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application   =>  cv_appl_name_xxwsh              -- �A�v���P�[�V�����Z�k��
                            ,iv_name          =>  cv_msg_xxwsh_13222              -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1   =>  cv_tkn_request_no               -- �g�[�N���R�[�h1
                            ,iv_token_value1  =>  l_get_ship_date_rec.request_no  -- �g�[�N���l1
                            ,iv_token_name2   =>  cv_tkn_err_msg                  -- �g�[�N���R�[�h2
                            ,iv_token_value2  =>  lv_err_msg                      -- �g�[�N���l2
                           );
             RAISE data_skip_expt;
           END IF;
--
           -- 5-14.���_���ڐύڃ`�F�b�N���s���܂��B(���ڌ�No�ɒl������ꍇ�̂�)
           IF ( gt_ship_line_data_tab(i).mixed_no IS NOT NULL ) THEN
--
             -- ������
             lt_based_w_mixed        := NULL;
             lt_sum_w_mixed          := NULL;
             lt_sum_pallet_w_mixed   := NULL;
             lt_small_amount_c_mixed := NULL;
             ln_chk_w_mixed_sum      := NULL;
--
             -- 5-14-1.���ڌ�No�̈˗��̏����擾
             BEGIN
               SELECT  NVL( xoha.based_weight,      cn_0 )  based_weight        -- ��{�d��
                      ,NVL( xoha.sum_weight,        cn_0 )  sum_weight          -- �ύڏd�ʍ��v
                      ,NVL( xoha.sum_pallet_weight, cn_0 )  sum_pallet_weight   -- ���v�p���b�g�d��
                      ,xhmv.small_amount_class              small_amount_class  -- �����敪
               INTO    lt_based_w_mixed
                      ,lt_sum_w_mixed
                      ,lt_sum_pallet_w_mixed
                      ,lt_small_amount_c_mixed
               FROM    xxwsh_order_headers_all xoha
                      ,xxwsh_ship_method_v     xhmv
               WHERE   xoha.request_no           = gt_ship_line_data_tab(i).mixed_no
               AND     xoha.latest_external_flag = cv_yes
               AND     xoha.mixed_no             = xoha.request_no
               AND     xhmv.ship_method_code     = xoha.shipping_method_code
               ;
             EXCEPTION
               WHEN OTHERS THEN
                 -- ���b�Z�[�W�ҏW
                 lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application   =>  cv_appl_name_xxwsh                 -- �A�v���P�[�V�����Z�k��
                                ,iv_name          =>  cv_msg_xxwsh_13240                 -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1   =>  cv_tkn_request_no                  -- �g�[�N���R�[�h1
                                ,iv_token_value1  =>  gt_ship_line_data_tab(i).mixed_no  -- �g�[�N���l1
                                ,iv_token_name2   =>  cv_tkn_err_msg                     -- �g�[�N���R�[�h2
                                ,iv_token_value2  =>  SQLERRM                            -- �g�[�N���l2
                               );
                 RAISE data_skip_expt;
             END;
--
             -- 5-14-2.����̍���No�̏����擾
             SELECT  SUM(NVL(xoha.sum_weight,0))          -- �ύڏd�ʍ��v(����No�P��)
                    ,SUM(NVL(xoha.sum_pallet_weight,0))   -- ���v�p���b�g�d��(����No�P��)
             INTO    ln_w_mixed_sum
                    ,ln_p_mixed_sum
             FROM    xxwsh_order_headers_all xoha
             WHERE   xoha.mixed_no             =  gt_ship_line_data_tab(i).mixed_no
             AND     xoha.latest_external_flag =  cv_yes
             AND     xoha.mixed_no             <> xoha.request_no
             ;
--
             -- 5-14-3.����̍���No�̐ύڏd�ʂ̃`�F�b�N
--
             -- �����敪�������̏ꍇ
             IF ( lt_small_amount_c_mixed = cv_amount_class_small ) THEN
               ln_chk_w_mixed_sum := lt_sum_w_mixed + ln_w_mixed_sum;  --�p���b�g�d�ʂȂ�
             -- �����敪�������ȊO�̏ꍇ
             ELSE
               ln_chk_w_mixed_sum := lt_sum_w_mixed + ln_w_mixed_sum + lt_sum_pallet_w_mixed + ln_p_mixed_sum;   --�p���b�g�d�ʂ���
             END IF;
             -- �v�Z�����ύڏd�ʍ��v > ���ڌ��̊�{�d�ʂ̏ꍇ
             IF ( ln_chk_w_mixed_sum > lt_based_w_mixed ) THEN
               -- ���b�Z�[�W�ҏW
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                 -- �A�v���P�[�V�����Z�k��
                              ,iv_name          =>  cv_msg_xxwsh_13241                 -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1   =>  cv_tkn_request_no                  -- �g�[�N���R�[�h1
                              ,iv_token_value1  =>  gt_ship_line_data_tab(i).mixed_no  -- �g�[�N���l1
                              ,iv_token_name2   =>  cv_max_weight                      -- �g�[�N���R�[�h2
                              ,iv_token_value2  =>  TO_CHAR( lt_based_w_mixed )        -- �g�[�N���l2
                              ,iv_token_name3   =>  cv_cur_weight                      -- �g�[�N���R�[�h3
                              ,iv_token_value3  =>  TO_CHAR( ln_chk_w_mixed_sum )      -- �g�[�N���l3
                             );
               RAISE data_skip_expt;
             END IF;
--
           END IF;
--
          -- ���������J�E���g
          gn_normal_cnt   := gn_normal_cnt + ln_suc_line_cnt;
          -- ���׌����̏�����
          ln_suc_line_cnt := 0;
--
        END IF;
--
      EXCEPTION
        -- *** �X�L�b�v�f�[�^��O ***
        WHEN data_skip_expt THEN
          -- �o�͂ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���O�ɕ\��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- �X�L�b�v�����J�E���g
          gn_skip_cnt     := gn_skip_cnt + ln_suc_line_cnt;
          -- ���׌����̏�����
          ln_suc_line_cnt := 0;
          -- 1���ł��X�L�b�v�f�[�^������ꍇ�͌x���Ƃ���
          ov_retcode      := cv_status_warn;
          -- ���[���o�b�N
          ROLLBACK TO SAVEPOINT req_unit_save;
      END;
--
      -- �x���f�[�^������ꍇ�A�x���I���Ƃ���
      IF ( gn_skip_cnt > 0 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
    END LOOP upd_data_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_ship_date_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_ship_date_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_order_data;
--
  /**********************************************************************************
   * Procedure Name   : del_data
   * Description      : �f�[�^�폜 (M-5)
   ***********************************************************************************/
  PROCEDURE del_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J�����[�U�[��`��O ***
    del_data_expt   EXCEPTION;     -- �폜�G���[
    -- *** ���[�J���ϐ� ***
    lv_error_token  VARCHAR2(20);  -- �g�[�N�����b�Z�[�W�i�[�p
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    -- M-5.1 �i�ڃ}�X�^�ꊇ�A�b�v���[�h�f�[�^�폜
    --==============================================================
    BEGIN
      DELETE
      FROM   xxwsh_order_upload_work  xouw
      WHERE  xouw.request_id = cn_request_id
      ;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg      := SQLERRM;
        lv_error_token := cv_msg_xxwsh_13230;
        RAISE del_data_expt;
    END;
    --
    --==============================================================
    -- M-5.2 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      DELETE
      FROM  xxinv_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = gn_file_id
      ;
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg      := SQLERRM;
        lv_error_token := cv_msg_xxwsh_13226;
        RAISE del_data_expt;
    END;
  EXCEPTION
--
    WHEN del_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_name_xxwsh
                    ,iv_name          => cv_msg_xxwsh_13223
                    ,iv_token_name1   => cv_tkn_table     --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => lv_error_token   --�e�[�u����
                    ,iv_token_name2   => cv_tkn_err_msg   --�p�����[�^2(�g�[�N��)
                    ,iv_token_value2  => lv_errmsg        --�G���[���b�Z�[�W
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,     --   1.�t�@�C���h�c
    iv_format     IN  VARCHAR2,     --   2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_warn_flag  VARCHAR2(1);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_skip_cnt   := 0;
    -- ���[�U�ϐ��̏�����
    lv_warn_flag  := cv_no;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_file_id  => iv_file_id      -- �t�@�C���h�c
      ,iv_format   => iv_format       -- �t�H�[�}�b�g�p�^�[��
      ,ov_errbuf   => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�擾(M-2)
    -- ===============================
    get_if_data(
       ov_errbuf   => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
--
    -- ===============================
    -- �o�׈˗��f�[�^�擾(M-3)
    -- ===============================
    get_ship_request_data(
       ov_errbuf   => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
    -- ===============================
    -- �󒍃A�h�I���X�V(M-4)
    -- ===============================
    upd_order_data(
       ov_errbuf   => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
    -- ===============================
    -- �f�[�^�폜(M-5)
    -- ===============================
    del_data(
       ov_errbuf   => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �x���f�[�^������ꍇ�͌x���I���Ƃ���
    IF ( lv_warn_flag = cv_yes ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id    IN  VARCHAR2,      --   1.�t�@�C���h�c
    iv_format     IN  VARCHAR2       --   2.�t�H�[�}�b�g�p�^�[��
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_file_id  -- �t�@�C���h�c
      ,iv_format   -- �t�H�[�}�b�g�p�^�[��
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    -- �����ݒ�
    gn_target_cnt := 0; -- �Ώی���
    gn_normal_cnt := 0; -- ��������
    gn_skip_cnt   := 0; -- �X�L�b�v����
    gn_error_cnt  := 1; -- �G���[����
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXWSH400013C;
/
