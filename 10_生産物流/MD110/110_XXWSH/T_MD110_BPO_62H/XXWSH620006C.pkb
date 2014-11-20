CREATE OR REPLACE PACKAGE BODY xxwsh620006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620006c(body)
 * Description      : �o�ɒ����\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �o�ɒ����\ T_MD070_BPO_62H
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  fnc_chg_date           FUNCTION  : ���t�^�ϊ�
 *  fnc_warning_judg       FUNCTION  : �x������
 *  prc_set_tag_data       PROCEDURE : �^�O���ݒ菈��
 *  prc_set_tag_data       PROCEDURE : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
 *  prc_initialize         PROCEDURE : ��������
 *  prc_get_report_data    PROCEDURE : ���[�f�[�^�擾����
 *  prc_set_xml_data_cmn   PROCEDURE : XML�f�[�^�ݒ�(�o�ׁE�ړ�����)
 *  prc_create_xml_data    PROCEDURE : XML��������
 *  fnc_convert_into_xml   FUNCTION  : XML�f�[�^�ϊ�
 *  submain                PROCEDURE : ���C�������v���V�[�W��
 *  main                   PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0   Nozomi Kashiwagi �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada       �N�C�b�N�R�[�h�x���敪�̌������O�������ɕύX(�o�׈ړ�)
 *  2008/6/20     1.2   Y.Shindo         �z���敪���VIEW2�̌������O�������ɕύX
 *  2008/07/03    1.3   Akiyoshi Shiina  �ύX�v���Ή�#92
 *                                       �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/10    1.4   Naoki Fukuda     �ړ��̊��Z�P�ʕs��Ή�
 *  2008/07/16    1.5   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�z��No���ݒ莞�͈˗�No���ɉ^���Ǝҏ����o��)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���������ʗ�O ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gc_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620006c' ;  -- �p�b�P�[�W��
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620006T' ;  -- ���[ID
  ------------------------------
  -- �o�ׁE�ړ�����
  ------------------------------
  -- �Ɩ����
  gc_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;        -- �o��
  gc_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;        -- �ړ�
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '�o��' ;     -- �o��
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '�ړ�' ;     -- �ړ�
  -- �����敪
  gc_small_kbn_obj           CONSTANT  VARCHAR2(1)  := '1' ;        -- �Ώ�
  gc_small_kbn_not_obj       CONSTANT  VARCHAR2(1)  := '0' ;        -- �ΏۊO
  -- ���ߌ�C���敪
  gc_modify_kbn_new          CONSTANT  VARCHAR2(1)  := 'N' ;        -- �V�K
  gc_modify_kbn_mod          CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �C��
  gc_modify_kbn_nm_new       CONSTANT  VARCHAR2(12) := '�V�K' ;     -- �V�K
  gc_modify_kbn_nm_mod       CONSTANT  VARCHAR2(12) := '�C��' ;     -- �C��
  -- �d�ʗe�ϋ敪
  gc_wei_cap_kbn_w           CONSTANT  VARCHAR2(1)  := '1' ;        -- �d��
  gc_wei_cap_kbn_c           CONSTANT  VARCHAR2(1)  := '2' ;        -- �e��
  -- �폜�E����t���O
  gc_delete_flg              CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �N�x�s��
  -- �x���敪
  gc_warn_kbn_over           CONSTANT  VARCHAR2(2)  := '10' ;       -- �ύ�(OVER)
  gc_warn_kbn_low            CONSTANT  VARCHAR2(2)  := '20' ;       -- �ύ�(LOW)
  gc_warn_kbn_lot            CONSTANT  VARCHAR2(2)  := '30' ;       -- ���b�g�t�]
  gc_warn_kbn_fresh          CONSTANT  VARCHAR2(2)  := '40' ;       -- �N�x�s��
  -- �i�ځE���i�敪
  gc_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;        -- ���i�敪:�h�����N
  gc_prod_cd_leaf            CONSTANT  VARCHAR2(1)  := '1' ;        -- ���i�敪:���[�t
  gc_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;        -- �i�ڋ敪:���i
  -- ���t�t�H�[�}�b�g
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- �N����
  gc_date_fmt_ymd_ja         CONSTANT  VARCHAR2(20) := 'YYYY"�N"MM"��"DD"��' ;   -- ����
  -- �o�̓^�O
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- �O���[�v�^�O
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- �f�[�^�^�O
  ------------------------------
  -- �o�׊֘A
  ------------------------------
  -- �o�׎x���敪
  gc_ship_pro_kbn_s          CONSTANT  VARCHAR2(1)  := '1' ;        -- �o�׈˗�
  -- �󒍃J�e�S��
  gc_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- �ԕi�i�󒍂̂݁j
  -- �ŐV�t���O
  gc_new_flg                 CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �ŐV�t���O
  -- �o�׈˗��X�e�[�^�X
  gc_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- ���ߍς�
  gc_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- ���
  ------------------------------
  -- �ړ��֘A
  ------------------------------
  -- �ړ��^�C�v
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;        -- �ϑ��Ȃ�
  -- �ړ��X�e�[�^�X
  gc_move_status_ordered     CONSTANT  VARCHAR2(2)  := '02' ;       -- �˗���
  gc_move_status_not         CONSTANT  VARCHAR2(2)  := '99' ;       -- ���
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_lookup_cd_freight       CONSTANT  VARCHAR2(30)  := 'XXWSH_FREIGHT_CLASS' ;        -- �^���敪
  gc_lookup_cd_warn          CONSTANT  VARCHAR2(30)  := 'XXWSH_WARNING_CLASS' ;        -- �x���敪
  gc_lookup_cd_conreq        CONSTANT  VARCHAR2(30)  := 'XXWSH_LG_CONFIRM_REQ_CLASS' ; -- �m�F�˗�
  ------------------------------
  -- �v���t�@�C���֘A
  ------------------------------
  gc_prof_name_weight        CONSTANT VARCHAR2(30)  := 'XXWSH_WEIGHT_UOM' ;   -- �o�׏d�ʒP��
  gc_prof_name_capacity      CONSTANT VARCHAR2(30)  := 'XXWSH_CAPACITY_UOM' ; -- �o�חe�ϒP��
  gc_prof_name_threshold     CONSTANT VARCHAR2(30)  := 'XXWSH_LE_THRESHOLD' ; -- �ύڌ����̂������l
  gc_prof_name_item_div      CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DIV_SECURITY' ; -- ���i�敪
  ------------------------------
  -- ���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;             -- ��޵�:�o�ץ������z��
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;             -- ��޵�:Ͻ���o�������
  --���b�Z�[�WID
  gc_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12301' ;   -- ���̧�َ擾�װ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;   -- ���[0���G���[
  --���b�Z�[�W-�g�[�N����
  gc_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;         -- �v���t�@�C����
  --���b�Z�[�W-�g�[�N���l
  gc_msg_tkn_val_prof_wei    CONSTANT  VARCHAR2(30) := 'XXWSH:�o�׏d�ʒP��' ;
  gc_msg_tkn_val_prof_cap    CONSTANT  VARCHAR2(30) := 'XXWSH:�o�חe�ϒP��' ;
  gc_msg_tkn_val_prof_thr    CONSTANT  VARCHAR2(30) := 'XXWSH:�ύڌ����̂������l' ;
  gc_msg_tkn_val_prof_user   CONSTANT  VARCHAR2(30) := '���[�U�[ID' ;
  gc_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN�F���i�敪(�Z�L�����e�B)' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���R�[�h�^�錾�p�e�[�u���ʖ��錾
  xoha   xxwsh_order_headers_all%ROWTYPE ;        -- �󒍃w�b�_�A�h�I��
  xola   xxwsh_order_lines_all%ROWTYPE ;          -- �󒍖��׃A�h�I��
  xottv  xxwsh_oe_transaction_types2_v%ROWTYPE ;  -- �󒍃^�C�v���VIEW2
  xtc    xxwsh_tightening_control%ROWTYPE ;       -- �o�׈˗����ߊǗ�(�A�h�I��)
  xilv   xxcmn_item_locations2_v%ROWTYPE ;        -- OPM�ۊǏꏊ���(�o�Ɍ�)
  xcv    xxcmn_carriers2_v%ROWTYPE ;              -- �^���Ǝҏ��
  xcs    xxwsh_carriers_schedule%ROWTYPE ;        -- �z�Ԕz���v��(�A�h�I��)
  xcav   xxcmn_cust_accounts2_v%ROWTYPE ;         -- �ڋq���
  xcasv  xxcmn_cust_acct_sites2_v%ROWTYPE ;       -- �ڋq�T�C�g���
  ximv   xxcmn_item_mst2_v%ROWTYPE ;              -- OPM�i�ڏ��
  xicv   xxcmn_item_categories4_v%ROWTYPE ;       -- OPM�i�ڃJ�e�S���������
  xsmv   xxwsh_ship_method2_v%ROWTYPE ;           -- �z���敪���
  xlv    xxcmn_lookup_values2_v%ROWTYPE ;         -- �N�C�b�N�R�[�h
  xmrih  xxinv_mov_req_instr_headers%ROWTYPE ;    -- �ړ��˗�/�w���w�b�_(�A�h�I��)
  xmril  xxinv_mov_req_instr_lines%ROWTYPE ;      -- �ړ��˗�/�w������(�A�h�I��)
--
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     concurrent_id        VARCHAR2(15)                      -- 01:�R���J�����gID
    ,biz_type             VARCHAR2(1)                       -- 02:�Ɩ����
    ,block1               xilv.distribution_block%TYPE      -- 03:�u���b�N1
    ,block2               xilv.distribution_block%TYPE      -- 04:�u���b�N2
    ,block3               xilv.distribution_block%TYPE      -- 05:�u���b�N3
    ,shiped_code          VARCHAR2(4)                       -- 06:�o�Ɍ�
    ,shiped_date_from     DATE                              -- 07:�o�ɓ�From
    ,shiped_date_to       DATE                              -- 08:�o�ɓ�To
    ,shiped_form          xoha.order_type_id%TYPE           -- 09:�o�Ɍ`��
    ,confirm_request      xoha.confirm_request_class%TYPE   -- 10:�m�F�˗�
    ,warning              VARCHAR2(15)                      -- 11:�x��
  );
  type_rec_param_data   rec_param_data ;
--
  ------------------------------
  -- �o�̓f�[�^�֘A
  ------------------------------
  -- �o�̓f�[�^�i�[�p���R�[�h
  TYPE rec_report_data IS RECORD(
     biz_type                       VARCHAR2(10)                          -- �Ɩ����
    ,shiped_code                    xoha.deliver_from%TYPE                -- �o�Ɍ�(�R�[�h)
    ,shiped_name                    xilv.description%TYPE                 -- �o�Ɍ��i���́j
    ,shiped_date                    xoha.schedule_ship_date%TYPE          -- �o�ɓ�
    -- ���ו�(�z��No�O���[�v)
    ,delivery_no                    xoha.delivery_no%TYPE                 -- �z��No
    ,arrive_date                    xoha.schedule_arrival_date%TYPE       -- ����
    ,shipping_method_code           xoha.shipping_method_code%TYPE        -- �z���敪(�R�[�h)
    ,shipping_method_name           xsmv.ship_method_meaning%TYPE         -- �z���敪(����)
    ,career_code                    xoha.freight_carrier_code%TYPE        -- �^���Ǝ�(�R�[�h)
    ,career_name                    xcv.party_short_name%TYPE             -- �^���Ǝ�(����)
    ,freight_charge_name            xlv.meaning%TYPE                      -- �^���敪(����)
    -- ���ו�(�˗�No/�ړ�No�O���[�v)
    ,req_move_no                    xoha.request_no%TYPE                  -- �˗�No/�ړ�No
    ,modify_flg                     VARCHAR2(10)                          -- ���ߌ�C���敪
    ,shiped_form                    xottv.transaction_type_name%TYPE      -- �o�Ɍ`��
    ,time_from                      xoha.arrival_time_from%TYPE           -- ���Ԏw��FROM
    ,time_to                        xoha.arrival_time_to%TYPE             -- ���Ԏw��TO
    ,mixed_no                       xoha.mixed_no%TYPE                    -- ���ڌ�No
    ,collected_pallet_qty           xoha.collected_pallet_qty%TYPE        -- �p���b�g�������
    ,po_number                      xoha.cust_po_number%TYPE              -- PO#
    ,confirm_request                xlv.meaning%TYPE                      -- �m�F�˗�
    ,description                    xoha.shipping_instructions%TYPE       -- �E�v
    ,base_code                      xoha.head_sales_branch%TYPE           -- �Ǌ����_(�R�[�h)
    ,base_name                      xcav.party_short_name%TYPE            -- �Ǌ����_(����)
    ,delivery_to_code               xoha.deliver_to%TYPE                  -- �z����^���ɐ�(�R�[�h)
    ,delivery_to_name               xcasv.party_site_full_name%TYPE       -- �z����^���ɐ�(����)
    ,delivery_to_address            VARCHAR2(60)                          -- �z����Z��
    ,delivery_to_phone              xcasv.phone%TYPE                      -- �d�b�ԍ�
    -- ���ו�(�i�ڃR�[�h)
    ,item_code                      xola.shipping_item_code%TYPE          -- �i��(�R�[�h)
    ,item_name                      ximv.item_short_name%TYPE             -- �i��(����)
    ,qty                            NUMBER                                -- ����
    ,qty_tani                       VARCHAR2(3)                           -- ����_�P��
    ,pallet_quantity                xola.pallet_quantity%TYPE             -- �p���b�g����
    ,layer_quantity                 xola.layer_quantity%TYPE              -- �i��
    ,case_quantity                  xola.case_quantity%TYPE               -- �P�[�X��
    ,warning                        xlv .meaning%TYPE                     -- �x��
    -- ���ו�(�˗�No�P�ʍ��v����)
    ,wei_cap_kbn                    xoha.weight_capacity_class%TYPE       -- �d�ʗe�ϋ敪
    ,req_sum_pallet_qty             xoha.pallet_sum_quantity%TYPE         -- �p���b�g���v����
    ,req_sum_weight                 xoha.sum_weight%TYPE                  -- �ύڏd�ʍ��v
    ,req_sum_capacity               xoha.sum_capacity%TYPE                -- �ύڗe�ύ��v
    ,req_eff_weight                 xoha.loading_efficiency_weight%TYPE   -- �d�ʐύڌ���
    ,req_eff_capacity               xoha.loading_efficiency_capacity%TYPE -- �e�ϐύڌ���
    -- ���ו�(�z��No�P�ʍ��v����)
    ,deli_eff_weight                xcs.loading_efficiency_weight%TYPE    -- �d�ʐύڌ���
    ,deli_eff_capacity              xcs.loading_efficiency_capacity%TYPE  -- �e�ϐύڌ���
-- 2008/07/03 A.Shiina v1.3 ADD Start
    ,freight_charge_code            xlv.lookup_code%TYPE                  -- �^���敪(�R�[�h)
    ,complusion_output_kbn          xcv.complusion_output_code%TYPE       -- �����o�͋敪
-- 2008/07/03 A.Shiina v1.3 ADD Start
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_param              rec_param_data ;        -- ���̓p�����[�^���
  gt_report_data_ship   list_report_data ;      -- �o�̓f�[�^(�o�חp)
  gt_report_data_move   list_report_data ;      -- �o�̓f�[�^(�ړ��p)
  gt_xml_data_table     xml_data ;              -- XML�f�[�^
  gv_dept_cd            VARCHAR2(10) ;          -- �S������
  gv_dept_nm            VARCHAR2(14) ;          -- �S����
--
  -- �v���t�@�C���l�擾���ʊi�[�p
  gv_weight_uom         VARCHAR2(3);            -- �o�׏d�ʒP��
  gv_capacity_uom       VARCHAR2(3);            -- �o�חe�ϒP��
  gv_le_threshold       NUMBER;                 -- �ύڌ����̂������l
  gv_user_id            fnd_user.user_id%TYPE;  -- ���[�UID
  gv_prod_kbn           VARCHAR2(1);            -- ���i�敪
--
  -- �x���敪����
  gv_warning_over       xlv.meaning%TYPE ;   -- �ύ�(OVER)
  gv_warning_low        xlv.meaning%TYPE ;   -- �ύ�(LOW)
--
  /**********************************************************************************
   * Function Name    : fnc_chg_date
   * Description      : ���t�^�ϊ�(��F2008/04/01 �� 01-APR-08)
   ***********************************************************************************/
  FUNCTION fnc_chg_date(
    iv_date     IN  VARCHAR2  -- YYYY/MM/DD�`���̓��t
  )RETURN DATE
  IS
  BEGIN
    -- ������̓��t(YYYY/MM/DD�`��)����t�^�ɕϊ����ĕԋp
    RETURN( FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ) ;
  END fnc_chg_date;
--
  /**********************************************************************************
   * Function Name    : fnc_warning_judg
   * Description      : �x������
   *                    �����̒l��ύڌ����̂������l��100�Ŕ�r���A
   *                    ��r���ʂ����Ɍx�����̂�Ԃ��B
   ***********************************************************************************/
  FUNCTION fnc_warning_judg(
    in_judg_val  IN  NUMBER
  )RETURN VARCHAR2
  IS
    lv_warning_nm  xxcmn_lookup_values2_v.meaning%TYPE ;
  BEGIN
    -- �ύڌ����̂������l����������ꍇ
    IF (in_judg_val < gv_le_threshold) THEN
      lv_warning_nm := gv_warning_low;
--
    -- 100%���������ꍇ
    ELSIF (in_judg_val > 100) THEN
      lv_warning_nm := gv_warning_over;
    END IF;
--
    RETURN (lv_warning_nm);
  END fnc_warning_judg;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : �^�O���ݒ菈��
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2                 -- �^�O��
    ,iv_tag_value      IN  VARCHAR2                 -- �f�[�^
    ,iv_tag_type       IN  VARCHAR2  DEFAULT NULL   -- �f�[�^
  )
  IS
    ln_data_index  NUMBER ;    -- XML�f�[�^�̃C���f�b�N�X
  BEGIN
    ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
    -- �^�O����ݒ�
    gt_xml_data_table(ln_data_index).tag_name := iv_tag_name ;
--
    IF ((iv_tag_value IS NULL) AND (iv_tag_type = gc_tag_type_tag)) THEN
      -- �O���[�v�^�O�ݒ�
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
    ELSE
      -- �f�[�^�^�O�ݒ�
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
      gt_xml_data_table(ln_data_index).tag_value := iv_tag_value;
    END IF;
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2  -- �^�O��
  )
  IS
  BEGIN
    prc_set_tag_data(iv_tag_name, NULL, gc_tag_type_tag);
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- �v���O������
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
    -- *** ���[�J���E��O���� ***
    get_prof_expt     EXCEPTION ;     -- �v���t�@�C���擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �v���t�@�C���擾
    -- ====================================================
    -- �o�׏d�ʒP�ʎ擾
    gv_weight_uom := FND_PROFILE.VALUE(gc_prof_name_weight) ;
    IF (gv_weight_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_wei
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �o�חe�ϒP�ʎ擾
    gv_capacity_uom := FND_PROFILE.VALUE(gc_prof_name_capacity) ;
    IF (gv_capacity_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_cap
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �ύڌ����̂������l�擾
    gv_le_threshold := FND_PROFILE.VALUE(gc_prof_name_threshold) ;
    IF (gv_le_threshold IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_thr
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ���[�UID
    gv_user_id := FND_GLOBAL.USER_ID ;
    IF (gv_user_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_user
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �E�ӁF���i�敪
    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
  EXCEPTION
    --*** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���[�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
    ov_errbuf      OUT   VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT   VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT   VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    -- -----------------------------------------------------
    -- �o�׈˗���񒊏o
    -- -----------------------------------------------------
    CURSOR cur_ship_data
    IS
      SELECT
        ---------------------------------------------------------------------------------------
        -- �w�b�_��
         TO_CHAR(gc_biz_type_nm_ship)    AS  biz_type               -- �Ɩ����
        ,xoha.deliver_from               AS  shiped_code            -- �o�Ɍ�(�R�[�h)
        ,xilv.description                AS  shiped_name            -- �o�Ɍ��i���́j
        ,xoha.schedule_ship_date         AS  shiped_date            -- �o�ɓ�
        ,xoha.delivery_no                AS  delivery_no            -- �z��No
        ,xoha.schedule_arrival_date      AS  arrive_date            -- ����
        ,xoha.shipping_method_code       AS  shipping_method_code   -- �z���敪(�R�[�h)
        ,xsmv.ship_method_meaning        AS  shipping_method_name   -- �z���敪(����)
        ,xoha.freight_carrier_code       AS  career_code            -- �^���Ǝ�(�R�[�h)
        ,xcv.party_short_name            AS  career_name            -- �^���Ǝ�(����)
        ,xlv1.meaning                    AS  freight_charge_name    -- �^���敪(����)
        ------------------------------------------------------------------------
        -- ���ו�-�˗�No�O���[�v
        ,xoha.request_no                 AS  req_move_no            -- �˗�No/�ړ�No
        ,CASE
          WHEN gt_param.concurrent_id IS NULL THEN  NULL
          ELSE (
            CASE
              WHEN xoha.corrected_tighten_class = gc_modify_kbn_new THEN gc_modify_kbn_nm_new
              WHEN xoha.corrected_tighten_class = gc_modify_kbn_mod THEN gc_modify_kbn_nm_mod
            END
          )
         END                             AS  modify_flg             -- ���ߌ�C���敪
        ,xottv.transaction_type_name     AS  shiped_form            -- �o�Ɍ`��
        ,xoha.arrival_time_from          AS  time_from              -- ���Ԏw��FROM
        ,xoha.arrival_time_to            AS  time_to                -- ���Ԏw��TO
        ,xoha.mixed_no                   AS  mixed_no               -- ���ڌ�No
        ,xoha.collected_pallet_qty       AS  collected_pallet_qty   -- �p���b�g�������
        ,xoha.cust_po_number             AS  po_number              -- PO#
        ,xlv3.meaning                    AS  confirm_request        -- �m�F�˗�
        ,xoha.shipping_instructions      AS  description            -- �E�v
        ,xoha.head_sales_branch          AS  base_code              -- �Ǌ����_(�R�[�h)
        ,xcav.party_short_name           AS  base_name              -- �Ǌ����_(����)
        ,xoha.deliver_to                 AS  delivery_to_code       -- �z����^���ɐ�(�R�[�h)
        ,xcasv.party_site_full_name      AS  delivery_to_name       -- �z����^���ɐ�(����)
        ,SUBSTRB(xcasv.address_line1 || xcasv.address_line2, 1, 60) 
                                         AS  delivery_to_address    -- �z����Z��
        ,xcasv.phone                     AS  delivery_to_phone      -- �d�b�ԍ�
        ---------------------------------------------------
        -- ���ו�-�i�ڃO���[�v
        ,xola.shipping_item_code         AS  item_code  --�i��(�R�[�h)
        ,ximv.item_short_name            AS  item_name  --�i��(����)
        ,CASE
           -- ���o�Ɋ��Z�P�ʂ��ݒ�ς� ���� �h�����N���i�܂��̓��[�t���i�̏ꍇ
           WHEN (ximv.conv_unit IS NOT NULL
              AND  xicv.item_class_code = gc_item_cd_prdct
              AND  ((xicv.prod_class_code = gc_prod_cd_drink) 
                OR  (xicv.prod_class_code = gc_prod_cd_leaf))
           ) THEN (xola.quantity / TO_NUMBER(CASE 
                                               WHEN ximv.num_of_cases > 0 THEN ximv.num_of_cases
                                               ELSE TO_CHAR(1)
                                             END)
           )
           ELSE xola.quantity
         END                     AS  qty -- ����
        ,CASE
          -- ���o�Ɋ��Z�P�ʂ����ݒ�
          WHEN ximv.conv_unit IS NULL THEN  ximv.item_um
          -- ���o�Ɋ��Z�P�ʂ��ݒ��
          ELSE ximv.conv_unit
         END                     AS   qty_tani            -- ����_�P��
        ,xola.pallet_quantity    AS   pallet_quantity     -- �p���b�g����
        ,xola.layer_quantity     AS   layer_quantity      -- �i��
        ,xola.case_quantity      AS   case_quantity       -- �P�[�X��
        ,xlv2.meaning            AS   warning             -- �x��
        -------------------------------------------------------------------------------
        -- ���ו�-�˗�No�P�ʍ��v����
        ,xoha.weight_capacity_class        AS  wei_cap_kbn           -- �d�ʗe�ϋ敪
        ,xoha.pallet_sum_quantity          AS  deli_sum_pallet_qty   -- �p���b�g����(�˗�No�P��)
        ,CASE
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xoha.sum_weight
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xoha.sum_weight + xoha.sum_pallet_weight
          WHEN xsmv.small_amount_class IS NULL THEN   -- 6/20�ǉ�
            NULL
         END                               AS req_sum_weight         -- �ύڏd�ʍ��v(�˗�No�P��)
        ,CASE
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xoha.sum_capacity
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xoha.sum_capacity + xoha.sum_pallet_weight
          WHEN xsmv.small_amount_class IS NULL THEN
            NULL
         END                               AS  req_sum_capacity      -- �ύڗe�ύ��v(�˗�No�P��)
        ,xoha.loading_efficiency_weight    AS  req_eff_weight        -- �d�ʐύڌ���(�˗�No�P��)
        ,xoha.loading_efficiency_capacity  AS  req_eff_capacity      -- �e�ϐύڌ���(�˗�No�P��)
        ,xcs.loading_efficiency_weight     AS  deli_eff_weight       -- �d�ʐύڌ���(�z��No�P��)
        ,xcs.loading_efficiency_capacity   AS  deli_eff_capacity     -- �e�ϐύڌ���(�z��No�P��)
-- 2008/07/03 A.Shiina v1.3 ADD Start
        ,xlv1.lookup_code                  AS  freight_charge_code   -- �^���敪(�R�[�h)
        ,xcv.complusion_output_code        AS  complusion_output_kbn -- �����o�͋敪
-- 2008/07/03 A.Shiina v1.3 ADD End
      FROM
         xxwsh_order_headers_all        xoha    -- 01:�󒍃w�b�_�A�h�I��
        ,xxwsh_order_lines_all          xola    -- 02:�󒍖��׃A�h�I��
        ,xxwsh_oe_transaction_types2_v  xottv   -- 03:�󒍃^�C�v���
        ,xxwsh_tightening_control       xtc     -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
        ,xxcmn_item_locations2_v        xilv    -- 05:OPM�ۊǏꏊ���(�o�Ɍ�)
        ,xxcmn_carriers2_v              xcv     -- 06:�^���Ǝҏ��
        ,xxwsh_carriers_schedule        xcs     -- 07:�z�Ԕz���v��(�A�h�I��)
        ,xxcmn_cust_accounts2_v         xcav    -- 08:�ڋq���(�Ǌ����_���)
        ,xxcmn_cust_acct_sites2_v       xcasv   -- 09:�ڋq�T�C�g���(�o�א���)
        ,xxcmn_item_mst2_v              ximv    -- 10:OPM�i�ڏ��
        ,xxcmn_item_categories4_v       xicv    -- 11:OPM�i�ڃJ�e�S���������
        ,xxwsh_ship_method2_v           xsmv    -- 12:�z���敪���
        ,xxcmn_lookup_values2_v         xlv1    -- 13:�N�C�b�N�R�[�h(�^���敪)
        ,xxcmn_lookup_values2_v         xlv2    -- 14:�N�C�b�N�R�[�h(�x���敪)
        ,xxcmn_lookup_values2_v         xlv3    -- 15:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
      WHERE
        ----------------------------------------------------------------------------------
        -- �w�b�_���
        ----------------------------------------------------------------------------------
        -- 01:�󒍃w�b�_�A�h�I��
             xoha.order_type_id           = xottv.transaction_type_id
        AND  xoha.order_type_id           = NVL(gt_param.shiped_form, xoha.order_type_id)
        AND  xoha.req_status             >= gc_ship_status_close    -- �X�e�[�^�X:���ߍς�
        AND  xoha.req_status             <> gc_ship_status_delete   -- �X�e�[�^�X:���
        AND  xoha.latest_external_flag    = gc_new_flg              -- �ŐV�t���O
        AND  (gt_param.confirm_request IS NULL
          OR  xoha.confirm_request_class  = gt_param.confirm_request
        )
        AND  ( 
               (gt_param.shiped_date_to IS NULL
               -- �p�����[�^.�o�ɓ�From�̂ݎw�肳�ꂽ�ꍇ
               AND  TRUNC(xoha.schedule_ship_date) >= TRUNC(gt_param.shiped_date_from)
          ) OR (gt_param.shiped_date_to IS NOT NULL
               -- �p�����[�^.�o�ɓ�From�A�p�����[�^.�o�ɓ�To�̗����w�肳�ꂽ�ꍇ
               AND  TRUNC(xoha.schedule_ship_date) >= TRUNC(gt_param.shiped_date_from)
               AND  TRUNC(xoha.schedule_ship_date) <= TRUNC(gt_param.shiped_date_to)
          )
        )
        -- 03:�󒍃^�C�v���VIEW2
        AND  xottv.shipping_shikyu_class  = gc_ship_pro_kbn_s       -- �o�׎x���敪:�o�׈˗�
        AND  xottv.order_category_code   <> gc_order_cate_ret       -- �󒍃J�e�S��:�ԕi
        -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
        AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
        AND  (gt_param.concurrent_id IS NULL
          OR  xoha.tightening_program_id = gt_param.concurrent_id
        )
        -- 05:OPM�ۊǏꏊ���(�o�Ɍ�)
        AND  xoha.deliver_from_id = xilv.inventory_location_id
        AND  (
              xoha.deliver_from = gt_param.shiped_code
          OR  xilv.distribution_block = gt_param.block1
          OR  xilv.distribution_block = gt_param.block2
          OR  xilv.distribution_block = gt_param.block3
          OR  ((gt_param.block1 IS NULL) AND (gt_param.block2 IS NULL) AND (gt_param.block3 IS NULL)
            AND (gt_param.shiped_code IS NULL))
        )
        -- 06:�^���Ǝҏ��
        AND  xoha.career_id = xcv.party_id(+)
        -- 08:�ڋq�T�C�g���(�Ǌ����_���)
        AND  xoha.head_sales_branch = xcav.party_number
        -- 09:�ڋq�T�C�g���(�o�א���)
        AND  xoha.deliver_to_id     = xcasv.party_site_id
        -- 07:�z�Ԕz���v��(�A�h�I��)
        AND  xoha.delivery_no       =  xcs.delivery_no(+)
        -- �x���敪�֘A
        AND  (
               (gt_param.warning IS NULL
          ) OR (gt_param.warning = gc_warn_kbn_over   --�u�ύ�(OVER)�v
                -- �d�ʗe�ϋ敪:�d��
                AND  (xoha.weight_capacity_class = gc_wei_cap_kbn_w
                    AND (xoha.loading_efficiency_weight > 100
                      OR ((xcs.loading_efficiency_weight  > 100) OR (xcs.delivery_no IS NULL))
                    )
                -- �d�ʗe�ϋ敪:�e��
                ) OR (xoha.weight_capacity_class = gc_wei_cap_kbn_c
                    AND (xoha.loading_efficiency_capacity > 100 
                      OR ((xcs.loading_efficiency_capacity  > 100) OR (xcs.delivery_no IS NULL))
                    )
                )
              
          ) OR (gt_param.warning = gc_warn_kbn_low   --�u�ύ�(LOW)�v
                -- �d�ʗe�ϋ敪:�d��
                AND  (xoha.weight_capacity_class = gc_wei_cap_kbn_w
                  AND (xoha.loading_efficiency_weight < gv_le_threshold
                    OR ((xcs.loading_efficiency_weight  < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                -- �d�ʗe�ϋ敪:�e��
                ) OR (xoha.weight_capacity_class = gc_wei_cap_kbn_c
                  AND (xoha.loading_efficiency_capacity < gv_le_threshold
                    OR ((xcs.loading_efficiency_capacity  < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                )
          ) OR (gt_param.warning = gc_warn_kbn_lot     --�u���b�g�t�]�v
                AND xola.warning_class = gc_warn_kbn_lot
          ) OR (gt_param.warning = gc_warn_kbn_fresh   --�u�N�x�s���v
                AND xola.warning_class = gc_warn_kbn_fresh
          )
        )
        -- 12:�z���敪���
        AND  xoha.shipping_method_code  =  xsmv.ship_method_code(+)   -- 6/20 �O�������ǉ�
        ----------------------------------------------------------------------------------
        -- ���׏��
        ----------------------------------------------------------------------------------
        -- 02:�󒍖��׃A�h�I��
        AND  xoha.order_header_id  = xola.order_header_id
        AND  xola.delete_flag     <> gc_delete_flg
        -- 10:OPM�i�ڏ��
        AND  xola.shipping_inventory_item_id = ximv.inventory_item_id
        -- 11:OPM�i�ڃJ�e�S���������
        AND  ximv.item_id = xicv.item_id
        AND  xicv.prod_class_code = gv_prod_kbn
        ----------------------------------------------------------------------------------
        -- �N�C�b�N�R�[�h
        ----------------------------------------------------------------------------------
        -- MOD START 2008/06/04 NAKADA �N�C�b�N�R�[�h�Ƃ̌������O�������ɏC��
        -- 10:�N�C�b�N�R�[�h(�^���敪)
        AND  xlv1.lookup_type(+) = gc_lookup_cd_freight
        AND  xoha.freight_charge_class = xlv1.lookup_code(+)
        -- 11:�N�C�b�N�R�[�h(�x���敪)
        AND  xlv2.lookup_type(+) = gc_lookup_cd_warn
        AND  xola.warning_class = xlv2.lookup_code(+)
        -- 11:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
        AND  xlv3.lookup_type(+) = gc_lookup_cd_conreq
        AND  xoha.confirm_request_class = xlv3.lookup_code(+)
        -- MOD END   2008/06/04 NAKADA 
        ----------------------------------------------------------------------------------
        -- �A�h�I���}�X�^�K�p��
        ----------------------------------------------------------------------------------
        -- 06:�^���Ǝҏ��
        AND  (xcv.party_id IS NULL
          OR (   TRUNC(xcv.start_date_active) <= TRUNC(gt_param.shiped_date_from)
            AND  (xcv.end_date_active IS NULL
              OR  TRUNC(xcv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
          )
        )
        -- 08:�ڋq���(�Ǌ����_���)
        AND  TRUNC(xcav.start_date_active)  <= TRUNC(gt_param.shiped_date_from)
        AND  (xcav.end_date_active IS NULL
          OR  TRUNC(xcav.end_date_active)  >= TRUNC(gt_param.shiped_date_from))
        -- 09:�ڋq�T�C�g���(�o�א���)
        AND  TRUNC(xcasv.start_date_active) <= TRUNC(gt_param.shiped_date_from)
        AND  (xcasv.end_date_active IS NULL
          OR  TRUNC(xcasv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
        -- 10:OPM�i�ڏ��
        AND  TRUNC(ximv.start_date_active)  <= TRUNC(gt_param.shiped_date_from)
        AND  (ximv.end_date_active IS NULL
          OR  TRUNC(ximv.end_date_active)  >= TRUNC(gt_param.shiped_date_from))
      ORDER BY
             shiped_code      ASC   -- �o�Ɍ��i�R�[�h�j
            ,shiped_date      ASC   -- �o�ɓ�
            ,arrive_date      ASC   -- ����
            ,delivery_no      ASC   -- �z��No
            ,base_code        ASC   -- �Ǌ����_
            ,delivery_to_code ASC   -- �z����
            ,req_move_no      ASC   -- �˗�No/�ړ�No
            ,item_code        ASC   -- �i�ڃR�[�h
      ;
--
    -- -----------------------------------------------------
    -- �ړ��˗���񒊏o
    -- -----------------------------------------------------
    CURSOR cur_move_data
    IS
      SELECT
        ---------------------------------------------------------------------------------------
        -- �w�b�_��
         TO_CHAR(gc_biz_type_nm_move)     AS  biz_type               --�Ɩ����
        ,xmrih.shipped_locat_code         AS  shiped_code            --�o�Ɍ�(�R�[�h)
        ,xilv1.description                AS  shiped_name            --�o�Ɍ��i���́j
        ,xmrih.schedule_ship_date         AS  shiped_date            --�o�ɓ�
        ,xmrih.delivery_no                AS  delivery_no            --�z��No
        ,xmrih.schedule_arrival_date      AS  arrive_date            --����
        ,xmrih.shipping_method_code       AS  shipping_method_code   --�z���敪(�R�[�h)
        ,xsmv.ship_method_meaning         AS  shipping_method_name   --�z���敪(����)
        ,xmrih.freight_carrier_code       AS  career_code            --�^���Ǝ�(�R�[�h)
        ,xcv.party_short_name             AS  career_name            --�^���Ǝ�(����)
        ,xlv1.meaning                     AS  freight_charge_name    --�^���敪(����)
        ---------------------------------------------------------------------------------------
        -- ���ו�-�˗�No�O���[�v
        ,xmrih.mov_num                    AS  req_move_no            --�˗�No/�ړ�No
        ,NULL                             AS  modify_flg             --���ߌ�C���敪
        ,NULL                             AS  shiped_form            --�o�Ɍ`��
        ,xmrih.arrival_time_from          AS  time_from              --���Ԏw��FROM
        ,xmrih.arrival_time_to            AS  time_to                --���Ԏw��TO
        ,NULL                             AS  mixed_no               --���ڌ�No
        ,xmrih.collected_pallet_qty       AS  collected_pallet_qty   --�p���b�g�������
        ,NULL                             AS  po_number              --PO#
        ,NULL                             AS  confirm_request        --�m�F�˗�
        ,xmrih.description                AS  description            --�E�v
        ,NULL                             AS  base_code              --�Ǌ����_(�R�[�h)
        ,NULL                             AS  base_name              --�Ǌ����_(����)
        ,xmrih.ship_to_locat_code         AS  delivery_to_code       --�z����^���ɐ�(�R�[�h)
        ,xilv2.description                AS  delivery_to_name       --�z����^���ɐ�(����)
        ,NULL                             AS  delivery_to_address    --�z����Z��
        ,NULL                             AS  delivery_to_phone      --�d�b�ԍ�
        ---------------------------------------------------
        -- ���ו�-�i�ڃO���[�v
        ,xmril.item_code                  AS  item_code              --�i��(�R�[�h)
        ,ximv.item_short_name             AS  item_name              --�i��(����)
        ,CASE
           -- ���o�Ɋ��Z�P�ʂ��ݒ�ς� ���� �h�����N���i�̏ꍇ
           WHEN (ximv.conv_unit IS NOT NULL
              AND  xicv.item_class_code = gc_item_cd_prdct
              AND  xicv.prod_class_code = gc_prod_cd_drink
           ) THEN (xmril.instruct_qty / TO_NUMBER(
                                          CASE 
                                            WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
                                            ELSE TO_CHAR(1)
                                          END)
           )
           ELSE  xmril.instruct_qty
         END                     AS  qty --����
        -- 2008/07/10 Fukuda Start --------------------------------------
        --,CASE
        --  -- ���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ
        --  WHEN ximv.conv_unit IS NULL THEN ximv.item_um
        --  -- ���o�Ɋ��Z�P�ʂ��ݒ�ς̏ꍇ
        --  ELSE ximv.conv_unit
        -- END                     AS  qty_tani            --����_�P��
        --
        ,CASE
           -- ���o�Ɋ��Z�P�ʂ��ݒ�ς� ���� �h�����N���i�̏ꍇ
           WHEN (ximv.conv_unit IS NOT NULL
              AND  xicv.item_class_code = gc_item_cd_prdct
              AND  xicv.prod_class_code = gc_prod_cd_drink
           ) THEN ximv.conv_unit
           ELSE ximv.item_um
         END                     AS  qty_tani            --����_�P��
        -- 2008/07/10 Fukuda END --------------------------------------------
        --
        ,xmril.pallet_quantity   AS  pallet_quantity     --�p���b�g����
        ,xmril.layer_quantity    AS  layer_quantity      --�i��
        ,xmril.case_quantity     AS  case_quantity       --�P�[�X��
        ,xlv2.meaning            AS  warning             --�x��
        -------------------------------------------------------------------------------
        -- ���ו�-�˗�No�P�ʍ��v
        ,xmrih.weight_capacity_class        AS  wei_cap_kbn          -- �d�ʗe�ϋ敪
        ,xmrih.pallet_sum_quantity          AS  deli_sum_pallet_qty  -- �p���b�g����(�˗�No�P��)
        ,CASE
          -- �����敪���Ώۂ̏ꍇ
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xmrih.sum_weight
          -- �����敪���ΏۊO�̏ꍇ
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xmrih.sum_weight + xmrih.sum_pallet_weight
          -- �����敪��NULL�̏ꍇ
          WHEN xsmv.small_amount_class IS NULL THEN   -- 6/20�ǉ�
            NULL
         END                                AS req_sum_weight         -- �ύڏd�ʍ��v(�˗�No�P��)
        ,CASE
          -- �����敪���Ώۂ̏ꍇ
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xmrih.sum_capacity
          -- �����敪���ΏۊO�̏ꍇ
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xmrih.sum_capacity + xmrih.sum_pallet_weight
          -- �����敪��NULL�̏ꍇ
          WHEN xsmv.small_amount_class IS NULL THEN   -- 6/20�ǉ�
            NULL
         END                                AS  req_sum_capacity      -- �ύڗe�ύ��v(�˗�No�P��)
        ,xmrih.loading_efficiency_weight    AS  req_eff_weight        -- �d�ʐύڌ���(�˗�No�P��)
        ,xmrih.loading_efficiency_capacity  AS  req_eff_capacity      -- �e�ϐύڌ���(�˗�No�P��)
        ,xcs.loading_efficiency_weight      AS  deli_eff_weight       -- �d�ʐύڌ���(�z��No�P��)
        ,xcs.loading_efficiency_capacity    AS  deli_eff_capacity     -- �e�ϐύڌ���(�z��No�P��)
-- 2008/07/03 A.Shiina v1.3 ADD Start
        ,xlv1.lookup_code                   AS  freight_charge_code   -- �^���敪(�R�[�h)
        ,xcv.complusion_output_code         AS  complusion_output_kbn -- �����o�͋敪
-- 2008/07/03 A.Shiina v1.3 ADD End
      FROM
             xxinv_mov_req_instr_headers    xmrih     -- 01:�ړ��˗�/�w���w�b�_(�A�h�I��)
            ,xxinv_mov_req_instr_lines      xmril     -- 02:�ړ��˗�/�w������(�A�h�I��)
            ,xxwsh_carriers_schedule        xcs       -- 03:�z�Ԕz���v��(�A�h�I��)
            ,xxcmn_item_locations2_v        xilv1     -- 04:OPM�ۊǏꏊ���(�o�Ɍ�)
            ,xxcmn_item_locations2_v        xilv2     -- 05:OPM�ۊǏꏊ���(���ɐ�)
            ,xxcmn_carriers2_v              xcv       -- 06:�^���Ǝҏ��
            ,xxcmn_item_mst2_v              ximv      -- 07:OPM�i�ڏ��
            ,xxcmn_item_categories4_v       xicv      -- 08:OPM�i�ڃJ�e�S���������
            ,xxwsh_ship_method2_v           xsmv      -- 09:�z���敪���
            ,xxcmn_lookup_values2_v         xlv1      -- 10:�N�C�b�N�R�[�h(�^���敪)
            ,xxcmn_lookup_values2_v         xlv2      -- 11:�N�C�b�N�R�[�h(�x���敪)
      WHERE
        ----------------------------------------------------------------------------------
        -- �w�b�_���
        ----------------------------------------------------------------------------------
        -- 01:�ړ��˗�/�w���w�b�_(�A�h�I��)
             xmrih.mov_type   <>  gc_mov_type_not_ship   --�ړ��^�C�v:�ϑ��Ȃ�
        AND  xmrih.status     >=  gc_move_status_ordered --�X�e�[�^�X:�˗���
        AND  xmrih.status     <>  gc_move_status_not     --�X�e�[�^�X:���
        -- 03:�z�Ԕz���v��(�A�h�I��)
        AND  xmrih.delivery_no      =  xcs.delivery_no(+)
        -- 04:OPM�ۊǏꏊ���(�o�Ɍ�)
        AND  xmrih.shipped_locat_id  = xilv1.inventory_location_id
        AND  (
              xmrih.shipped_locat_code = gt_param.shiped_code
          OR  xilv1.distribution_block = gt_param.block1
          OR  xilv1.distribution_block = gt_param.block2
          OR  xilv1.distribution_block = gt_param.block3
          OR  (gt_param.block1 IS NULL) AND (gt_param.block2 IS NULL) AND (gt_param.block3 IS NULL)
            AND (gt_param.shiped_code IS NULL)
        )
        -- �o�ɓ��֘A
        AND  ( (gt_param.shiped_date_to IS NULL
                -- �p�����[�^.�o�ɓ�From�̂ݎw�肳�ꂽ�ꍇ
               AND  xmrih.schedule_ship_date >= TRUNC(gt_param.shiped_date_from)
          ) OR (gt_param.shiped_date_to IS NOT NULL
                -- �p�����[�^.�o�ɓ�From�A�p�����[�^.�o�ɓ�To�̗����w�肳�ꂽ�ꍇ
               AND  xmrih.schedule_ship_date >= TRUNC(gt_param.shiped_date_from)
               AND  xmrih.schedule_ship_date <= TRUNC(gt_param.shiped_date_to)
          )
        )
        -- 06:�^���Ǝҏ��
        AND  xmrih.career_id         =  xcv.party_id(+)
        -- 05:OPM�ۊǏꏊ���(���ɐ�)
        AND  xmrih.ship_to_locat_id  =  xilv2.inventory_location_id
        -- �x���敪�֘A
        AND  (
               (gt_param.warning IS NULL
          ) OR (gt_param.warning = gc_warn_kbn_over   --�u�ύ�(OVER)�v
                --�d�ʗe�ϋ敪:�d��
                AND  (xmrih.weight_capacity_class = gc_wei_cap_kbn_w
                    AND (xmrih.loading_efficiency_weight > 100
                      OR ((xcs.loading_efficiency_weight > 100) OR (xcs.delivery_no IS NULL))
                    )
                --�d�ʗe�ϋ敪:�e��
                ) OR (xmrih.weight_capacity_class = gc_wei_cap_kbn_c
                    AND (xmrih.loading_efficiency_capacity > 100
                      OR ((xcs.loading_efficiency_capacity > 100) OR (xcs.delivery_no IS NULL))
                    )
                )
              
          ) OR (gt_param.warning = gc_warn_kbn_low   --�u�ύ�(LOW)�v
                --�d�ʗe�ϋ敪:�d��
                AND  (xmrih.weight_capacity_class = gc_wei_cap_kbn_w
                  AND (xmrih.loading_efficiency_weight < gv_le_threshold
                    OR ((xcs.loading_efficiency_weight < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                --�d�ʗe�ϋ敪:�e��
                ) OR (xmrih.weight_capacity_class = gc_wei_cap_kbn_c
                  AND (xmrih.loading_efficiency_capacity < gv_le_threshold
                    OR ((xcs.loading_efficiency_capacity < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                )
          ) OR (gt_param.warning = gc_warn_kbn_lot   --�u���b�g�t�]�v
                AND xmril.warning_class = gc_warn_kbn_lot
          ) OR (gt_param.warning = gc_warn_kbn_fresh--�u�N�x�s���v
                AND xmril.warning_class = gc_warn_kbn_fresh
          )
        )
        -- 09:�z���敪���
        AND  xmrih.shipping_method_code  =  xsmv.ship_method_code(+)  -- 6/20 �O�������ǉ�
        ----------------------------------------------------------------------------------
        -- ���׏��
        ----------------------------------------------------------------------------------
        -- 02:�ړ��˗�/�w������(�A�h�I��)
        AND  xmrih.mov_hdr_id   = xmril.mov_hdr_id
        AND  xmril.delete_flg  <> gc_delete_flg    --����t���O
        -- 07:OPM�i�ڏ��
        AND  xmril.item_id = ximv.item_id
        -- 08:OPM�i�ڃJ�e�S���������
        AND  xmril.item_id = xicv.item_id
        AND  xicv.prod_class_code = gv_prod_kbn
        ----------------------------------------------------------------------------------
        -- �N�C�b�N�R�[�h
        ----------------------------------------------------------------------------------
        -- 10:�N�C�b�N�R�[�h(�^���敪)
        -- MOD START 2008/06/04 NAKADA �N�C�b�N�R�[�h�Ƃ̌������O�������ɏC��
        AND  xlv1.lookup_type(+) = gc_lookup_cd_freight
        AND  xmrih.freight_charge_class = xlv1.lookup_code(+)
        -- 11:�N�C�b�N�R�[�h(�x���敪)
        AND  xlv2.lookup_type(+) = gc_lookup_cd_warn
        AND  xmril.warning_class = xlv2.lookup_code(+)
        -- MOD END   2008/06/04 NAKADA 
        ----------------------------------------------------------------------------------
        -- �A�h�I���}�X�^�K�p��
        ----------------------------------------------------------------------------------
        -- 06:�^���Ǝҏ��
        AND  (xcv.party_id IS NULL
          OR (   TRUNC(xcv.start_date_active)  <= TRUNC(gt_param.shiped_date_from)
            AND  (xcv.end_date_active IS NULL
              OR  TRUNC(xcv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
          )
        )
        -- 07:OPM�i�ڏ��
        AND  TRUNC(ximv.start_date_active) <= TRUNC(gt_param.shiped_date_from)
        AND  (ximv.start_date_active IS NULL
          OR  TRUNC(ximv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
      ORDER BY
             shiped_code      ASC   -- �o�Ɍ��i�R�[�h�j
            ,shiped_date      ASC   -- �o�ɓ�
            ,arrive_date      ASC   -- ����
            ,delivery_no      ASC   -- �z��No
            ,base_code        ASC   -- �Ǌ����_
            ,delivery_to_code ASC   -- �z����
            ,req_move_no      ASC   -- �˗�No/�ړ�No
            ,item_code        ASC   -- �i�ڃR�[�h
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S���ҏ��擾
    -- ====================================================
    -- �S������
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(gv_user_id), 1, 10) ;
    -- �S����
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(gv_user_id), 1, 14) ;
--
    -- ====================================================
    -- �x���敪���̎擾
    -- ====================================================
    -- �ύ�(OVER)�̖��̂��擾
    SELECT xlvv.meaning
    INTO   gv_warning_over
    FROM   xxcmn_lookup_values2_v xlvv
    WHERE  xlvv.lookup_type = gc_lookup_cd_warn
      AND  xlvv.lookup_code = gc_warn_kbn_over ;
--
    -- �ύ�(LOW)�̖��̂��擾
    SELECT xlvv.meaning
    INTO   gv_warning_low
    FROM   xxcmn_lookup_values2_v xlvv
    WHERE  xlvv.lookup_type = gc_lookup_cd_warn
      AND  xlvv.lookup_code = gc_warn_kbn_low ;
--
    -- ====================================================
    -- ���[�f�[�^�擾
    -- ====================================================
    -- �u�o�ׁv���w�肳�ꂽ�ꍇ
    IF ((gt_param.biz_type = gc_biz_type_cd_ship) OR (gt_param.biz_type IS NULL)) THEN
      -- �o�׈˗����擾
      OPEN cur_ship_data ;
      FETCH cur_ship_data BULK COLLECT INTO gt_report_data_ship ;
      CLOSE cur_ship_data ;
    END IF;
--
    -- �u�ړ��v���w�肳�ꂽ�ꍇ
    IF ((gt_param.biz_type = gc_biz_type_cd_move) OR (gt_param.biz_type IS NULL)) THEN
      -- �ړ��˗����擾
      OPEN cur_move_data ;
      FETCH cur_move_data BULK COLLECT INTO gt_report_data_move ;
      CLOSE cur_move_data ;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( cur_ship_data%ISOPEN ) THEN
        CLOSE cur_ship_data ;
      END IF ;
      IF ( cur_move_data%ISOPEN ) THEN
        CLOSE cur_move_data ;
      END IF ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( cur_ship_data%ISOPEN ) THEN
        CLOSE cur_ship_data ;
      END IF ;
      IF ( cur_move_data%ISOPEN ) THEN
        CLOSE cur_move_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( cur_ship_data%ISOPEN ) THEN
        CLOSE cur_ship_data ;
      END IF ;
      IF ( cur_move_data%ISOPEN ) THEN
        CLOSE cur_move_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_xml_data_cmn
   * Description      : XML�f�[�^�ݒ�(�o�ׁE�ړ�����)
   ***********************************************************************************/
  PROCEDURE prc_set_xml_data_cmn(
     it_data    IN  list_report_data
  )
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �O�񃌃R�[�h�i�[�p
    lv_tmp_biz_type         type_report_data.biz_type%TYPE DEFAULT NULL ;        -- �Ɩ����
    lv_tmp_shiped_cd        type_report_data.shiped_code%TYPE DEFAULT NULL ;     -- �o�Ɍ��R�[�h
    lv_tmp_shiped_date      type_report_data.shiped_date%TYPE DEFAULT NULL ;     -- �o�ɓ�
    lv_tmp_delivery_no      type_report_data.delivery_no%TYPE DEFAULT NULL ;     -- �z��No
    lv_tmp_req_move_no      type_report_data.req_move_no%TYPE DEFAULT NULL ;     -- �˗�No/�ړ�No
    lv_tmp_base_code        type_report_data.base_code%TYPE DEFAULT NULL ;       -- �Ǌ����_�R�[�h
    lv_tmp_deli_to_code     type_report_data.delivery_to_code%TYPE DEFAULT NULL ;-- �z����
--
    -- �^�O�o�͔���t���O
    lb_dispflg_biz_type     BOOLEAN DEFAULT TRUE ;       -- �Ɩ����
    lb_dispflg_shiped_cd    BOOLEAN DEFAULT TRUE ;       -- �o�Ɍ��R�[�h
    lb_dispflg_shiped_date  BOOLEAN DEFAULT TRUE ;       -- �o�ɓ�
    lb_dispflg_delivery_no  BOOLEAN DEFAULT TRUE ;       -- �z��No
    lb_dispflg_req_move_no  BOOLEAN DEFAULT TRUE ;       -- �˗�No/�ړ�No
--
    -- ���v�Z�o�p
    ln_sum_qty              NUMBER DEFAULT 0 ;      -- ���ʍ��v
    ln_sum_pallet_qty       NUMBER DEFAULT 0 ;      -- �p���b�g�������v
    ln_sum_weight           NUMBER DEFAULT 0 ;      -- �ύڏd�ʍ��v
    ln_sum_capacity         NUMBER DEFAULT 0 ;      -- �ύڗe�ύ��v
--
  BEGIN
--
    -- -----------------------------------------------------
    -- XML�f�[�^�쐬
    -- -----------------------------------------------------
    <<set_data_loop>>
    FOR i IN 1..it_data.COUNT LOOP
--
      -- ====================================================
      -- XML�f�[�^�ݒ�
      -- ====================================================
      -- �w�b�_��(�Ɩ���ʃO���[�v)
      IF (lb_dispflg_biz_type) THEN
        prc_set_tag_data('g_business_info') ;
        prc_set_tag_data('report_id'       , gc_report_id);
        prc_set_tag_data('exec_time'       , TO_CHAR(SYSDATE, gc_date_fmt_all));
        prc_set_tag_data('dep_cd'          , gv_dept_cd);
        prc_set_tag_data('dep_nm'          , gv_dept_nm);
        prc_set_tag_data('shiped_date_from', TO_CHAR(gt_param.shiped_date_from,gc_date_fmt_ymd_ja));
        prc_set_tag_data('shiped_date_to'  , TO_CHAR(gt_param.shiped_date_to,gc_date_fmt_ymd_ja));
        prc_set_tag_data('business_type'   , it_data(i).biz_type);
        prc_set_tag_data('lg_shiped_cd_info') ;
      END IF ;
--
      -- �w�b�_��(�o�Ɍ��O���[�v)
      IF (lb_dispflg_shiped_cd) THEN
        prc_set_tag_data('g_shiped_cd_info');
        prc_set_tag_data('shiped_cd', it_data(i).shiped_code);
        prc_set_tag_data('shiped_nm', it_data(i).shiped_name);
        prc_set_tag_data('lg_shiped_date_info');
      END IF ;
--
      -- �w�b�_��(�o�ɓ��O���[�v)
      IF (lb_dispflg_shiped_date) THEN
        prc_set_tag_data('g_shiped_date_info');
        prc_set_tag_data('shiped_date', TO_CHAR(it_data(i).shiped_date, gc_date_fmt_ymd));
        prc_set_tag_data('lg_delivery_info');
      END IF ;
--
      -- ���ו�(�z��No�O���[�v)
      IF (lb_dispflg_delivery_no) THEN
        prc_set_tag_data('g_delivery_info');
        prc_set_tag_data('delivery_no'    , it_data(i).delivery_no);
        prc_set_tag_data('arrive_date'    , TO_CHAR(it_data(i).arrive_date, gc_date_fmt_ymd));
        prc_set_tag_data('delivery_kbn'   , it_data(i).shipping_method_code);
        prc_set_tag_data('delivery_nm'    , it_data(i).shipping_method_name);
-- 2008/07/03 A.Shiina v1.3 Update Start
       IF  ((it_data(i).freight_charge_code  = '1')
        OR (it_data(i).complusion_output_kbn = '1')) THEN
        prc_set_tag_data('carrier_cd'     , it_data(i).career_code);
        prc_set_tag_data('carrier_nm'     , it_data(i).career_name);
       END IF;
-- 2008/07/03 A.Shiina v1.3 Update End
        prc_set_tag_data('freight_kbn_nm' , it_data(i).freight_charge_name);
        prc_set_tag_data('lg_req_move_info');
      END IF ;
--
      -- ���ו�(�˗�No/�ړ�No�O���[�v)
      IF (lb_dispflg_req_move_no) THEN
        prc_set_tag_data('g_req_move_info');
        prc_set_tag_data('req_move_no'         , it_data(i).req_move_no);
        prc_set_tag_data('modify_kbn'          , it_data(i).modify_flg);
        prc_set_tag_data('shiped_type'         , it_data(i).shiped_form);
        prc_set_tag_data('time_from'           , it_data(i).time_from);
        prc_set_tag_data('time_to'             , it_data(i).time_to);
        prc_set_tag_data('mixed_no'            , it_data(i).mixed_no);
        prc_set_tag_data('collected_pallet_qty', it_data(i).collected_pallet_qty);
        prc_set_tag_data('po_number'           , it_data(i).po_number);
        prc_set_tag_data('confirm_request'     , it_data(i).confirm_request);
        prc_set_tag_data('tekiyo'              , it_data(i).description);
--
        -- �Ǌ����_��񂪑O�񃌃R�[�h�ƈقȂ�ꍇ�̂ݏo��
        IF ((lv_tmp_base_code != it_data(i).base_code) OR lb_dispflg_delivery_no)  THEN
          prc_set_tag_data('sales_branch_cd'    , it_data(i).base_code);
          prc_set_tag_data('sales_branch_nm'    , it_data(i).base_name);
        END IF;
--
        -- �z�����񂪑O�񃌃R�[�h�ƈقȂ�ꍇ�̂ݏo��
        IF ((lv_tmp_deli_to_code != it_data(i).delivery_to_code) OR lb_dispflg_delivery_no)  THEN
          prc_set_tag_data('delivery_to_cd'     , it_data(i).delivery_to_code);
          prc_set_tag_data('delivery_to_nm'     , it_data(i).delivery_to_name);
          prc_set_tag_data('delivery_to_address', it_data(i).delivery_to_address);
          prc_set_tag_data('delivery_to_phone'  , it_data(i).delivery_to_phone);
        END IF;
--
        prc_set_tag_data('lg_item_info');
      END IF ;
--
      -- ���ו�(�i�ڃR�[�h�O���[�v)
      prc_set_tag_data('g_item_info');
      prc_set_tag_data('item_cd'   , it_data(i).item_code);
      prc_set_tag_data('item_nm'   , it_data(i).item_name);
      prc_set_tag_data('qty'       , it_data(i).qty);
      prc_set_tag_data('qty_tani'  , it_data(i).qty_tani);
      prc_set_tag_data('pallet_qty', it_data(i).pallet_quantity);
      prc_set_tag_data('layer_qty' , it_data(i).layer_quantity);
      prc_set_tag_data('case_qty'  , it_data(i).case_quantity);
      prc_set_tag_data('warning'   , it_data(i).warning);
      prc_set_tag_data('/g_item_info');
--
      -- ====================================================
      -- ���ݏ������̃f�[�^��ێ�
      -- ====================================================
      lv_tmp_biz_type     := it_data(i).biz_type ;
      lv_tmp_shiped_cd    := it_data(i).shiped_code ;
      lv_tmp_shiped_date  := it_data(i).shiped_date ;
      lv_tmp_delivery_no  := it_data(i).delivery_no ;
      lv_tmp_req_move_no  := it_data(i).req_move_no ;
      lv_tmp_base_code    := it_data(i).base_code ;
      lv_tmp_deli_to_code := it_data(i).delivery_to_code ;
--
      -- ====================================================
      -- �o�͔���
      -- ====================================================
      IF (i < it_data.COUNT) THEN
--
        -- �˗�No/�ړ�No
        IF (lv_tmp_req_move_no = it_data(i + 1).req_move_no) THEN
          lb_dispflg_req_move_no := FALSE ;
        ELSE
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- �z��No
--mod start 1.5
--        IF (NVL(lv_tmp_delivery_no,'NULL') = NVL(it_data(i + 1).delivery_no,'NULL')) THEN
        IF (lv_tmp_delivery_no = it_data(i + 1).delivery_no) THEN
--mod end 1.5
          --�z��No���ݒ肳��Ă���A�O���R�[�h�Ɠ����ꍇ�͓���O���[�v
          lb_dispflg_delivery_no := FALSE ;
--add start 1.5
        ELSIF (it_data(i + 1).delivery_no IS NULL AND lb_dispflg_req_move_no = FALSE) THEN
          --�z��No�����ݒ�ŁA�˗�No���O���R�[�h�Ɠ����ꍇ�͓���O���[�v
          lb_dispflg_delivery_no := FALSE ;
--add end 1.5
        ELSE
          --��L�ȊO(�z��No���قȂ�A�z��No�����ݒ�ň˗�No���O���R�[�h�Ɠ���)�͕ʃO���[�v
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- �o�ɓ�
        IF (lv_tmp_shiped_date = it_data(i + 1).shiped_date) THEN
          lb_dispflg_shiped_date := FALSE ;
        ELSE
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- �o�Ɍ��R�[�h
        IF (lv_tmp_shiped_cd = it_data(i + 1).shiped_code) THEN
          lb_dispflg_shiped_cd   := FALSE ;
        ELSE
          lb_dispflg_shiped_cd   := TRUE ;
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- �Ɩ����
        IF (lv_tmp_biz_type = it_data(i + 1).biz_type) THEN
          lb_dispflg_biz_type    := FALSE ;
        ELSE
          lb_dispflg_biz_type    := TRUE ;
          lb_dispflg_shiped_cd   := TRUE ;
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_biz_type    := TRUE ;
          lb_dispflg_shiped_cd   := TRUE ;
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
      END IF;
--
      -- ====================================================
      -- �I���^�O�ݒ�
      -- ====================================================
      IF (lb_dispflg_req_move_no) THEN
--
        prc_set_tag_data('/lg_item_info') ;
        prc_set_tag_data('req_sum_pallet_qty'  , it_data(i).req_sum_pallet_qty);
--
        -- -----------------------------------------------------
        -- �˗�No�P�ʍ��v���ڐݒ�
        -- -----------------------------------------------------
        -- �d�ʂ̏ꍇ
        IF (it_data(i).wei_cap_kbn = gc_wei_cap_kbn_w) THEN
          prc_set_tag_data('req_sum_wei_cap'     , it_data(i).req_sum_weight);
          prc_set_tag_data('req_sum_wei_cap_tani', gv_weight_uom);
          prc_set_tag_data('req_sum_efficiency'  , it_data(i).req_eff_weight);
          prc_set_tag_data('req_warning'         , fnc_warning_judg(it_data(i).req_eff_weight));
--
          -- �z��No���v���ډ��Z
          ln_sum_weight := ln_sum_weight + it_data(i).req_sum_weight ;
--
        -- �e�ς̏ꍇ
        ELSIF (it_data(i).wei_cap_kbn = gc_wei_cap_kbn_c) THEN
          prc_set_tag_data('req_sum_wei_cap'     , it_data(i).req_sum_capacity);
          prc_set_tag_data('req_sum_wei_cap_tani', gv_capacity_uom);
          prc_set_tag_data('req_sum_efficiency'  , it_data(i).req_eff_capacity);
          prc_set_tag_data('req_warning'         , fnc_warning_judg(it_data(i).req_eff_capacity) );
--
          -- �z��No���v���ډ��Z
          ln_sum_capacity := ln_sum_capacity + it_data(i).req_sum_capacity ;
--
        END IF;
--
        -- �p���b�g�������v���ډ��Z
        ln_sum_pallet_qty := ln_sum_pallet_qty + it_data(i).req_sum_pallet_qty ;
--
        prc_set_tag_data('/g_req_move_info') ;
      END IF;
--
      IF (lb_dispflg_delivery_no) THEN
        prc_set_tag_data('/lg_req_move_info') ;
--
        -- -----------------------------------------------------
        -- �z��No�P�ʍ��v���ڐݒ�
        -- -----------------------------------------------------
        prc_set_tag_data('deli_sum_pallet_qty'    , ln_sum_pallet_qty);
        prc_set_tag_data('deli_sum_weight'        , ln_sum_weight);
        prc_set_tag_data('deli_sum_weight_tani'   , gv_weight_uom);
        prc_set_tag_data('deli_sum_capacity'      , ln_sum_capacity);
        prc_set_tag_data('deli_sum_capacity_tani' , gv_capacity_uom);
        prc_set_tag_data('deli_sum_eff_weight'    , it_data(i).deli_eff_weight);
        prc_set_tag_data('deli_sum_eff_capacity'  , it_data(i).deli_eff_capacity);
        prc_set_tag_data('deli_warning'
          ,fnc_warning_judg(it_data(i).deli_eff_weight + it_data(i).deli_eff_capacity) );
        prc_set_tag_data('/g_delivery_info') ;
--
        -- -----------------------------------------------------
        -- ���v�ϐ�������
        -- -----------------------------------------------------
        ln_sum_qty        := 0 ;
        ln_sum_pallet_qty := 0 ;
        ln_sum_weight     := 0 ;
        ln_sum_capacity   := 0 ;
--
      END IF;
--
      IF (lb_dispflg_shiped_date) THEN
        prc_set_tag_data('/lg_delivery_info') ;
        prc_set_tag_data('/g_shiped_date_info') ;
      END IF;
--
      IF (lb_dispflg_shiped_cd) THEN
        prc_set_tag_data('/lg_shiped_date_info') ;
        prc_set_tag_data('/g_shiped_cd_info') ;
      END IF;
--
      IF (lb_dispflg_biz_type) THEN
        prc_set_tag_data('/lg_shiped_cd_info') ;
        prc_set_tag_data('/g_business_info') ;
      END IF;
--
    END LOOP set_data_loop;
--
  END prc_set_xml_data_cmn ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML��������
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -----------------------------------------------------
    -- �w�b�_���ݒ�
    -- -----------------------------------------------------
    prc_set_tag_data('root') ;
    prc_set_tag_data('data_info') ;
    prc_set_tag_data('lg_business_info') ;
--
    -- -----------------------------------------------------
    -- ���[0���pXML�f�[�^�쐬
    -- -----------------------------------------------------
    IF ((gt_report_data_ship.COUNT = 0) AND (gt_report_data_move.COUNT = 0)) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
--
      prc_set_tag_data('g_business_info') ;
      prc_set_tag_data('lg_shiped_cd_info') ;
      prc_set_tag_data('g_shiped_cd_info') ;
      prc_set_tag_data('lg_shiped_date_info') ;
      prc_set_tag_data('g_shiped_date_info') ;
      prc_set_tag_data('msg' , ov_errmsg) ;
      prc_set_tag_data('/g_shiped_date_info') ;
      prc_set_tag_data('/lg_shiped_date_info') ;
      prc_set_tag_data('/g_shiped_cd_info') ;
      prc_set_tag_data('/lg_shiped_cd_info') ;
      prc_set_tag_data('/g_business_info');
    END IF ;
--
    -- -----------------------------------------------------
    -- XML�f�[�^�쐬
    -- -----------------------------------------------------
    -- �o�׈˗����ݒ�
    prc_set_xml_data_cmn(gt_report_data_ship);
    -- �ړ��˗����ݒ�
    prc_set_xml_data_cmn(gt_report_data_move);
--
    -- ====================================================
    -- �I���^�O�ݒ�
    -- ====================================================
    prc_set_tag_data('/lg_business_info') ;
    prc_set_tag_data('/data_info') ;
    prc_set_tag_data('/root') ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    ir_xml  IN xml_rec
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_data VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ir_xml.tag_type = 'D') THEN
      lv_data :=
    '<'|| ir_xml.tag_name || '><![CDATA[' || ir_xml.tag_value || ']]></' || ir_xml.tag_name || '>';
    ELSE
      lv_data := '<' || ir_xml.tag_name || '>';
    END IF ;
--
    RETURN(lv_data);
--
  END fnc_convert_into_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT   VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- �v���O������
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
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ��������
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- ���[�f�[�^�擾����
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML��������
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML�o�͏���
    -- ==================================================
    -- XML�w�b�_���o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- XML�f�[�^�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, fnc_convert_into_xml(gt_xml_data_table(i)) ) ;
    END LOOP xml_loop ;
--
    --XML�f�[�^�폜
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn)
      AND (gt_report_data_ship.COUNT = 0) AND (gt_report_data_move.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** ���[0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
     errbuf                 OUT    VARCHAR2      -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode                OUT    VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
    ,iv_concurrent_id       IN     VARCHAR2      -- 01:�R���J�����gID
    ,iv_biz_type            IN     VARCHAR2      -- 02:�Ɩ����
    ,iv_block1              IN     VARCHAR2      -- 03:�u���b�N1
    ,iv_block2              IN     VARCHAR2      -- 04:�u���b�N2
    ,iv_block3              IN     VARCHAR2      -- 05:�u���b�N3
    ,iv_shiped_code         IN     VARCHAR2      -- 06:�o�Ɍ�
    ,iv_shiped_date_from    IN     VARCHAR2      -- 07:�o�ɓ�From  ���K�{
    ,iv_shiped_date_to      IN     VARCHAR2      -- 08:�o�ɓ�To
    ,iv_shiped_form         IN     VARCHAR2      -- 09:�o�Ɍ`��
    ,iv_confirm_request     IN     VARCHAR2      -- 10:�m�F�˗�
    ,iv_warning             IN     VARCHAR2      -- 11:�x��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    -- ���̓p�����[�^���O���[�o���ϐ��ɕێ�
    gt_param.concurrent_id     :=  iv_concurrent_id ;                  -- 01:�R���J�����gID
    gt_param.biz_type          :=  iv_biz_type ;                       -- 02:�Ɩ����
    gt_param.block1            :=  iv_block1 ;                         -- 03:�u���b�N1
    gt_param.block2            :=  iv_block2 ;                         -- 04:�u���b�N2
    gt_param.block3            :=  iv_block3 ;                         -- 05:�u���b�N3
    gt_param.shiped_code       :=  iv_shiped_code ;                    -- 06:�o�Ɍ�
    gt_param.shiped_date_from  :=  fnc_chg_date(iv_shiped_date_from) ; -- 07:�o�ɓ�From
    gt_param.shiped_date_to    :=  fnc_chg_date(SUBSTR(iv_shiped_date_to, 1, 10)) ; -- 08:�o�ɓ�To
    gt_param.shiped_form       :=  iv_shiped_form ;                    -- 09:�o�Ɍ`��
    gt_param.confirm_request   :=  iv_confirm_request ;                -- 10:�m�F�˗�
    gt_param.warning           :=  iv_warning ;                        -- 11:�x��
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh620006c;
/
