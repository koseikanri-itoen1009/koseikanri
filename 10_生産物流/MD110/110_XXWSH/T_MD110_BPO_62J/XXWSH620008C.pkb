CREATE OR REPLACE PACKAGE BODY xxwsh620008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620008c(body)
 * Description      : �ύ��w����
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �ύ��w���� T_MD070_BPO_62J
 * Version          : 1.5
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prcsub_set_xml_data       �^�O���ݒ菈��
 *  prcsub_set_xml_data       �^�O���ݒ菈��(�J�n�E�I���^�O�p)
 *  convert_into_xml          �w�l�k�^�O�ɕϊ�����B
 *  insert_xml_plsql_table    XML�f�[�^�i�[
 *  prc_initialize            �v���t�@�C���l�擾�A�S���ҏ�񒊏o(H-1,H-2)
 *  prc_get_report_data       ���׃f�[�^�擾(H-3)
 *  prc_create_xml_data       �w�l�k�f�[�^�쐬(H-4)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/25    1.0   Yoshitomo Kawasaki �V�K�쐬
 *  2008/06/23    1.1   Yoshikatsu Shindou �z���敪���VIEW�̃����[�V�������O�������ɕύX
 *                                         �����敪��NULL�̎��̏�����ǉ�
 *  2008/07/03    1.2   Jun Nakada         ST�s��Ή�No412 �d�ʗe�ς̏������ʐ؂�グ
 *  2008/07/07    1.3   Akiyoshi Shiina    �ύX�v���Ή�#92
 *                                         �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/15    1.4   Masayoshi Uehara   �����̏�������؂�̂ĂāA�����ŕ\��
 *  2008/10/27    1.5   Yuko Kawano        �����w�E#133�A�ۑ�#32,#62�A�����ύX#183�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal             CONSTANT VARCHAR2(1)   := '0' ;
  gv_status_warn               CONSTANT VARCHAR2(1)   := '1' ;
  gv_status_error              CONSTANT VARCHAR2(1)   := '2' ;
  gv_msg_part                  CONSTANT VARCHAR2(3)   := ' : ' ;
  gv_msg_cont                  CONSTANT VARCHAR2(3)   := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                   CONSTANT VARCHAR2(20) :=  'xxwsh620008c';       -- �p�b�P�[�W��
  gc_report_id                  CONSTANT VARCHAR2(12) :=  'XXWSH620008T';       -- ���[ID
  gc_tag_type_tag               CONSTANT VARCHAR2(1)  :=  'T' ;     -- �o�̓^�O�^�C�v�iT�F�^�O�j
  gc_tag_type_data              CONSTANT VARCHAR2(1)  :=  'D' ;     -- �o�̓^�O�^�C�v�iD�F�f�[�^�j
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_quick_code_gyoumushubetsu  CONSTANT VARCHAR2(23) :=  'XXWSH_SHIPPING_BIZ_TYPE' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn            CONSTANT VARCHAR2(5)  :=  'XXCMN' ;   -- �A�v���P�[�V�����iXXCMN�j
  gc_application_wsh            CONSTANT VARCHAR2(5)  :=  'XXWSH' ;   -- �A�v���P�[�V����(XXWSH)
  -- ����0���p���b�Z�[�W
  gc_xxcmn_10122                CONSTANT VARCHAR2(15) :=  'APP-XXCMN-10122' ;
  -- �v���t�@�C���擾�G���[
  gc_msg_id_not_get_prof        CONSTANT VARCHAR2(15) :=  'APP-XXWSH-12301' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format              CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD' ;
  gc_char_dt_format             CONSTANT VARCHAR2(21) :=  'YYYY/MM/DD HH24:MI:SS' ;
  gc_tag_p_format               CONSTANT VARCHAR2(9)  :=  '99990.900' ;
  gc_tag_b_format               CONSTANT VARCHAR2(10) :=  '9999990.90' ;
  lc_date_jikanshitei_format    CONSTANT VARCHAR2(6)  :=  'HH24MI' ;
--
  ------------------------------
  -- �v���t�@�C���֘A
  ------------------------------
  gc_prof_name_weight           CONSTANT VARCHAR2(20) :=  'XXWSH_WEIGHT_UOM' ;    -- �o�׏d�ʒP��
  gc_prof_name_capacity         CONSTANT VARCHAR2(20) :=  'XXWSH_CAPACITY_UOM' ;  -- �o�חe�ϒP��
  --���b�Z�[�W-�g�[�N����
  gc_msg_tkn_nm_prof            CONSTANT VARCHAR2(10) :=  'PROF_NAME' ;           -- �v���t�@�C����
  --���b�Z�[�W-�g�[�N���l
  gc_msg_tkn_val_prof_wei       CONSTANT VARCHAR2(20) :=  'XXWSH:�o�׏d�ʒP��' ;
  gc_msg_tkn_val_prof_cap       CONSTANT VARCHAR2(20) :=  'XXWSH:�o�חe�ϒP��' ;
--
  gc_msg_shizisyo               CONSTANT VARCHAR2(6)  :=  '�w����' ;
  -- ���[�o�͖����Z�b�g
  gc_out_char_title_shukko      CONSTANT VARCHAR2(4)  :=  '�o��' ;
  gc_out_char_title_idou        CONSTANT VARCHAR2(4)  :=  '�ړ�' ;
--
  -- �o��(CODE)
  gc_code_shukka                CONSTANT VARCHAR2(1)  :=  '1' ;
--
  gc_tehai_label                CONSTANT VARCHAR2(8)  :=  '��zNo�F' ;            -- ��z��
--
-- 2008/10/27 Y.Kawano Add Start
  gc_class_y                    CONSTANT VARCHAR2(1)  :=  'Y';  -- �敪�l'Y'
-- 2008/10/27 Y.Kawano Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      -- 01 : �Ɩ����
       iv_business_type       VARCHAR2(1)
      -- 02:�u���b�N�P
      ,iv_block_1             xxcmn_item_locations2_v.distribution_block%TYPE
      -- 03:�u���b�N�Q
      ,iv_block_2             xxcmn_item_locations2_v.distribution_block%TYPE
      -- 04:�u���b�N�R
      ,iv_block_3             xxcmn_item_locations2_v.distribution_block%TYPE
      -- 05:�o�Ɍ�
      ,iv_delivery_origin     xxwsh_order_headers_all.deliver_from%TYPE
      -- 06:�o�ɓ�
      ,iv_delivery_day        xxwsh_order_headers_all.schedule_ship_date%TYPE
      -- 07:�z����
      ,iv_delivery_no         xxwsh_order_headers_all.delivery_no%TYPE
      -- 08:�o�Ɍ`��
      ,iv_delivery_form       xxwsh_oe_transaction_types_v.transaction_type_id%TYPE
      -- 09 : �Ǌ����_
      ,iv_jurisdiction_base   xxwsh_order_headers_all.head_sales_branch%TYPE
      -- 10 : �z����/���ɐ�
      ,iv_addre_delivery_dest xxwsh_order_headers_all.deliver_to%TYPE
      -- 11 : �˗���/�ړ���
      ,iv_request_movement_no xxwsh_order_headers_all.request_no%TYPE
      -- 12 : ���i�敪
      ,iv_commodity_div       xxcmn_item_categories4_v.prod_class_code%TYPE
    ) ;
--
  -- �ύ��w�����擾���R�[�h�ϐ�(�o�ׁA�ړ�����)
  TYPE rec_data_type_dtl  IS RECORD 
    (
      -- �Ɩ����
       gyoumu_shubetsu        VARCHAR2(4)
      -- �z��No
      ,delivery_no            xxwsh_order_headers_all.delivery_no%TYPE
      -- �o�Ɍ�(�R�[�h)
      ,deliver_from           xxwsh_order_headers_all.deliver_from%TYPE
      -- �o�Ɍ�(����)
      ,description            xxcmn_item_locations2_v.description%TYPE
      -- �^���Ǝ�(�R�[�h)
      ,freight_carrier_code   xxwsh_order_headers_all.freight_carrier_code%TYPE
      -- �^���Ǝ�(����)
      ,party_short_name1      xxcmn_carriers2_v.party_short_name%TYPE
      -- �˗�No�^�ړ�No
      ,request_no             xxwsh_order_headers_all.request_no%TYPE
      -- �o�Ɍ`��
      ,transaction_type_name  xxwsh_oe_transaction_types_v.transaction_type_name%TYPE
      -- �z����^���ɐ�(�R�[�h)
      ,deliver_to             xxwsh_order_headers_all.deliver_to%TYPE
      -- �z����^���ɐ�(����)
      ,party_site_name        xxcmn_cust_acct_sites2_v.party_site_name%TYPE
      -- �z���敪(�R�[�h)
      ,shipping_method_code   xxwsh_order_headers_all.shipping_method_code%TYPE
      -- �z���敪(����)
      ,ship_method_meaning    xxwsh_ship_method2_v.ship_method_meaning%TYPE
      -- �Ǌ����_(�R�[�h)
      ,head_sales_branch      xxwsh_order_headers_all.head_sales_branch%TYPE
      -- �Ǌ����_(����)
      ,party_name             xxcmn_cust_accounts2_v.party_name%TYPE
      -- �o�ɓ�
      ,schedule_ship_date     xxwsh_order_headers_all.schedule_ship_date%TYPE
      -- ����
      ,schedule_arrival_date  xxwsh_order_headers_all.schedule_arrival_date%TYPE
      -- ���Ԏw��From
      ,arrival_time_from      xxwsh_order_headers_all.arrival_time_from%TYPE
      -- ���Ԏw��To
      ,arrival_time_to        xxwsh_order_headers_all.arrival_time_to%TYPE
      -- �E�v
      ,shipping_instructions  xxwsh_order_headers_all.shipping_instructions%TYPE
      -- ��zNo
      ,batch_no               xxinv_mov_req_instr_headers.batch_no%TYPE
      -- �i��(�R�[�h)
      ,shipping_item_code     xxwsh_order_lines_all.shipping_item_code%TYPE
      -- �i��(����)
      ,item_short_name        xxcmn_item_mst2_v.item_short_name%TYPE
      -- ���b�gNo
      ,lot_no                 xxinv_mov_lot_details.lot_no%TYPE
      -- ������
      ,attribute1             ic_lots_mst.attribute1%TYPE
      -- �ܖ�����
      ,attribute3             ic_lots_mst.attribute3%TYPE
      -- �ŗL�L��
      ,attribute2             ic_lots_mst.attribute2%TYPE
      -- ����
      ,qty                    xxcmn_item_mst2_v.num_of_cases%TYPE
      -- ���v��(���גP��)
      ,sum_quantity           xxwsh_order_lines_all.quantity%TYPE
      -- ���v��_�P��(���גP��)
      ,sum_item_um            xxcmn_item_mst2_v.item_um%TYPE
      -- ���v�d��(���גP��)
      ,sum_weight_mei         xxwsh_order_headers_all.sum_weight%TYPE
      -- ���v�e��(���גP��)
      ,sum_capacity_mei       xxwsh_order_headers_all.sum_capacity%TYPE
      -- �˗��d��(�˗����v�P��)
      ,sum_weight_irai        xxwsh_order_headers_all.sum_weight%TYPE
      -- �˗��e��(�˗����v�P��)
      ,sum_capacity_irai      xxwsh_order_headers_all.sum_capacity%TYPE
-- 2008/07/07 A.Shiina v1.3 ADD Start
      -- �^���敪
      ,freight_charge_code    xxwsh_order_headers_all.freight_charge_class%TYPE
      -- �����o�͋敪
      ,complusion_output_kbn  xxcmn_carriers2_v.complusion_output_code%TYPE
-- 2008/07/07 A.Shiina v1.3 ADD End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gd_exec_date              DATE ;                -- ���{��
  gv_department_code        VARCHAR2(10) ;        -- �S������
  gv_department_name        VARCHAR2(14) ;        -- �S����
--
  gt_main_data              tab_data_type_dtl ;   -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;            -- XML�f�[�^
--
  --�P��
  gv_uom_weight             VARCHAR2(3);
  gv_uom_capacity           VARCHAR2(3);
--
  gv_out_char_title         VARCHAR2(4);
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : prcsub_set_xml_data
   * Description      : �^�O���ݒ菈��
   ***********************************************************************************/
  PROCEDURE prcsub_set_xml_data(
     ivsub_tag_name       IN  VARCHAR2                 -- �^�O��
    ,ivsub_tag_value      IN  VARCHAR2                 -- �f�[�^
    ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- �f�[�^
  )
  IS
    ln_data_index  NUMBER ;    -- XML�f�[�^��ݒ肷��C���f�b�N�X
  BEGIN
    ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
    gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
--
    IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
      -- �^�O�o��
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
    ELSE
      -- �f�[�^�o��
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
      gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
    END IF;
  END prcsub_set_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : prcsub_set_xml_data
   * Description      : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
   ***********************************************************************************/
  PROCEDURE prcsub_set_xml_data(
     ivsub_tag_name       IN  VARCHAR2  -- �^�O��
  )
  IS
  BEGIN
    prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
  END prcsub_set_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml(
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
  ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XML�f�[�^�i�[
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
     iv_tag_name       IN     VARCHAR2
    ,iv_tag_value      IN     VARCHAR2
    ,ic_tag_type       IN     CHAR
    ,ic_tag_value_type IN     CHAR                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iox_xml_data      IN OUT NOCOPY xml_data
  )     
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xml_plsql_table'; -- �v���O������
--
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_count  NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    lv_count                            := iox_xml_data.COUNT + 1 ;
    iox_xml_data(lv_count).TAG_NAME     := iv_tag_name ;
--
    IF ( ic_tag_value_type = 'P' ) THEN
      iox_xml_data(lv_count).TAG_VALUE  := TO_CHAR(TO_NUMBER(iv_tag_value), gc_tag_p_format) ;
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(lv_count).TAG_VALUE  := TO_CHAR(TO_NUMBER(iv_tag_value), gc_tag_b_format) ;
    ELSE
      iox_xml_data(lv_count).TAG_VALUE  := iv_tag_value ;
    END IF;
    iox_xml_data(lv_count).TAG_TYPE     := ic_tag_type ;
--
  END insert_xml_plsql_table ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �v���t�@�C���l�擾�A�S���ҏ�񒊏o(H-1,H-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ov_errbuf     OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt     NUMBER := 0 ;   -- �f�[�^�����擾�p
    lv_err_code     VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    get_prof_expt   EXCEPTION ;     -- �v���t�@�C���擾��O�n���h��
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �v���t�@�C���擾(H-1)
    -- ====================================================
    -- ====================================================
    -- �o�׏d�ʒP�ʎ擾
    -- ====================================================
    gv_uom_weight := FND_PROFILE.VALUE(gc_prof_name_weight) ;
    IF (gv_uom_weight IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_wei
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ====================================================
    -- �o�חe�ϒP�ʎ擾
    -- ====================================================
    gv_uom_capacity := FND_PROFILE.VALUE(gc_prof_name_capacity) ;
    IF (gv_uom_capacity IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_cap
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ====================================================
    -- �S���ҏ�񒊏o(H-2)
    -- ====================================================
    -- ====================================================
    -- �S�������擾
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(H-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
    lc_code_seihin                  CONSTANT VARCHAR2(1)  :=  '5' ;         -- ���i
    lc_code_genryou                 CONSTANT VARCHAR2(1)  :=  '1' ;         -- ����
    lc_code_hanseihin               CONSTANT VARCHAR2(1)  :=  '4' ;         -- �����i
    lc_item_cd_shizai               CONSTANT  VARCHAR2(1) :=  '2' ;          -- ����
    lc_small_amount_enabled         CONSTANT VARCHAR2(1)  :=  '1' ;         -- �����敪���Ώ�
    lc_small_amount_disabled        CONSTANT VARCHAR2(1)  :=  '0' ;         -- �����敪���ΏۊO
    lc_employee_division_inside     CONSTANT VARCHAR2(1)  :=  '1' ;         -- �]�ƈ��敪(1:����)
    lc_employee_division_outside    CONSTANT VARCHAR2(1)  :=  '2' ;         -- �]�ƈ��敪(2:�O��)
    lc_fixa_notif_end               CONSTANT VARCHAR2(2)  :=  '40' ;        -- �m��ʒm��
    lc_record_type_shizi            CONSTANT VARCHAR2(2)  :=  '10' ;        -- ���R�[�h�^�C�v(�w��)
    lc_doc_type_shukka_irai         CONSTANT VARCHAR2(2)  :=  '10' ;        -- ���̓^�C�v(�o�׈˗�)
    lc_doc_type_idou                CONSTANT VARCHAR2(2)  :=  '20' ;        -- ���̓^�C�v(�ړ�)
    lc_category_return              CONSTANT VARCHAR2(6)  :=  'RETURN' ;    -- �ԕi(�󒍂̂�)
    lc_status_shimezumi             CONSTANT VARCHAR2(2)  :=  '03' ;        -- ���ߍς�
    lc_status_torikeshi             CONSTANT VARCHAR2(2)  :=  '99' ;        -- ���
    lc_status_irai_zumi             CONSTANT VARCHAR2(2)  :=  '02' ;        -- �˗���
    lc_mov_type_sekisou_nashi       CONSTANT VARCHAR2(1)  :=  '2' ;         -- �ϑ�����
    lc_shikyu_cls_shukka_irai       CONSTANT VARCHAR2(1)  :=  '1' ;         -- �o�׈˗�
    lc_delete_flag                  CONSTANT VARCHAR2(1)  :=  'Y' ;         -- �폜�t���O
    -- �N�C�b�N�R�[�h���VIEW(�o��/�z���敪)
    lc_quick_code_shu_haisou_kbn    CONSTANT VARCHAR2(27) :=  'XXWSH_620F_SHIP_DELIV_CLASS' ;
--
    -- *** ���[�J���E�J�[�\�� ***
    ------------------------------------------------------------------------
    -- �o�ׂ̏ꍇ
    ------------------------------------------------------------------------
    CURSOR cur_main_data1
      (
         in_block_1               VARCHAR2
        ,in_block_2               VARCHAR2
        ,in_block_3               VARCHAR2
        ,in_delivery_origin       VARCHAR2
        ,in_delivery_day          VARCHAR2
        ,in_delivery_no           VARCHAR2
        ,in_delivery_form         VARCHAR2
        ,in_jurisdiction_base     VARCHAR2
        ,in_addre_delivery_dest   VARCHAR2
        ,in_request_movement_no   VARCHAR2
        ,in_commodity_div         VARCHAR2
      )
    IS
      SELECT
                 '�o��'                           AS gyoumu_shubetsu        -- �Ɩ����
                ,xoha.delivery_no                 AS delivery_no            -- �z��No
                ,xoha.deliver_from                AS deliver_from           -- �o�Ɍ�(�R�[�h)
                ,xil2v.description                AS description            -- �o�Ɍ�(����)
                ,xoha.freight_carrier_code        AS freight_carrier_code   -- �^���Ǝ�(�R�[�h)
                ,xc2v.party_short_name            AS party_short_name1      -- �^���Ǝ�(����)
                ,xoha.request_no                  AS request_no             -- �˗�No�^�ړ�No
                ,xott2v.transaction_type_name     AS transaction_type_name  -- �o�Ɍ`��
                ,xoha.deliver_to                  AS deliver_to             -- �z����^���ɐ�(����)
                ,xcas2v.party_site_full_name      AS party_site_full_name   -- �z����^���ɐ�(����)
                ,xoha.shipping_method_code        AS shipping_method_code   -- �z���敪(�R�[�h)
                ,xsm2v.ship_method_meaning        AS ship_method_meaning    -- �z���敪(����)
                ,xoha.head_sales_branch           AS head_sales_branch      -- �Ǌ����_(�R�[�h)
                ,xca2v.party_name                 AS party_name             -- �Ǌ����_(����)
                ,xoha.schedule_ship_date          AS schedule_ship_date     -- �o�ɓ�
                ,xoha.schedule_arrival_date       AS schedule_arrival_date  -- ����
                ,xoha.arrival_time_from           AS arrival_time_from      -- ���Ԏw��From
                ,xoha.arrival_time_to             AS arrival_time_to        -- ���Ԏw��To
                ,xoha.shipping_instructions       AS shipping_instructions  -- �E�v
                ,''                               AS tehai_no               -- ��zNo
                ,xola.shipping_item_code          AS shipping_item_code     -- �i��(�R�[�h)
                ,xim2v1.item_short_name           AS item_short_name        -- �i��(����)
                ,xmldt.lot_no                     AS lot_no                 -- ���b�gNo
                ,ilm.attribute1                   AS attribute1             -- ������
                ,ilm.attribute3                   AS attribute3             -- �ܖ�����
                ,ilm.attribute2                   AS attribute2             -- �ŗL�L��
                ,CASE
                  -- ���i�̏ꍇ
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN ((xic4v1.item_class_code = lc_code_seihin) 
                  WHEN ((xic5v1.item_class_code = lc_code_seihin) 
-- 2008/10/27 Y.Kawano Mod End #183
                         AND 
                        (ilm.attribute6 IS NOT NULL)) THEN 
                          xim2v1.num_of_cases
                  -- ���̑��̕i�ڂ̏ꍇ
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN (((xic4v1.item_class_code = lc_code_genryou) 
--                          OR  
--                          (xic4v1.item_class_code = lc_code_hanseihin))
                  WHEN (((xic5v1.item_class_code = lc_code_genryou) 
                          OR  
                          (xic5v1.item_class_code = lc_code_hanseihin))
-- 2008/10/27 Y.Kawano Mod End #183
                        AND 
                        (ilm.attribute6 IS NOT NULL)) THEN 
                         TO_CHAR(TRUNC(ilm.attribute6))
                  -- �݌ɓ������ݒ肳��Ă��Ȃ�,���ޑ�,���b�g�Ǘ����Ă��Ȃ��ꍇ
                  WHEN ( ilm.attribute6 IS NULL ) THEN TO_CHAR(TRUNC(xim2v1.frequent_qty))
                END                               AS qty            -- ����
                ,CASE
                  WHEN  xmldt.mov_line_id IS NULL THEN
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin  THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin  THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xola.quantity / TO_NUMBER(
                                                CASE WHEN xim2v1.num_of_cases > 0
                                                        THEN xim2v1.num_of_cases
                                                     ELSE TO_CHAR(1)
                                                END)
                      ELSE
                        xola.quantity
                    END
                  ELSE
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin  THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin  THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xmldt.actual_quantity / TO_NUMBER(
                                                        CASE WHEN xim2v1.num_of_cases > 0
                                                                THEN xim2v1.num_of_cases
                                                             ELSE TO_CHAR(1)
                                                        END)
                      ELSE
                        xmldt.actual_quantity
                    END
                END                               AS sum_quantity   -- ���v��(���גP��)
                ,CASE
                  WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #32,#183
--                  AND   xic4v1.item_class_code  = lc_code_seihin  THEN
                  AND   xic5v1.item_class_code  = lc_code_seihin
                  AND   xim2v1.num_of_cases > '0'  THEN
-- 2008/10/27 Y.Kawano Mod End   #32,#183
                    xim2v1.conv_unit
                  ELSE
                    xim2v1.item_um
                END                               AS sum_item_um    -- ���v��_�P��(���גP��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xoha.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xoha.sum_weight + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- ���v�d��(���גP��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xoha.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xoha.sum_capacity + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- ���v�e��(���גP��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xoha.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xoha.sum_weight + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- �˗��d��(�˗����v�P��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN   
                    xoha.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xoha.sum_capacity + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- �˗��e��(�˗����v�P��)
-- 2008/07/07 A.Shiina v1.3 ADD Start
                ,xoha.freight_charge_class        AS freight_charge_code    -- �^���敪
                ,xc2v.complusion_output_code      AS complusion_output_kbn  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.3 ADD End
--
      FROM
                 xxwsh_order_headers_all          xoha              -- �󒍃w�b�_�A�h�I��
                ,xxwsh_order_lines_all            xola              -- �󒍖��׃A�h�I��
                ,xxwsh_oe_transaction_types2_v    xott2v            -- �󒍃^�C�v���VIEW
                ,xxcmn_item_locations2_v          xil2v             -- OPM�ۊǏꏊ���VIEW2
                ,xxcmn_cust_acct_sites2_v         xcas2v            -- �ڋq�T�C�g���VIEW2
                ,xxcmn_cust_accounts2_v           xca2v             -- �ڋq���VIEW2
                ,xxcmn_carriers2_v                xc2v              -- �^���Ǝҏ��VIEW2
                ,xxinv_mov_lot_details            xmldt             -- �ړ����b�g�ڍ�(�A�h�I��)
                ,ic_lots_mst                      ilm               -- OPM���b�g�}�X�^
                ,xxcmn_item_mst2_v                xim2v1            -- OPM�i�ڏ��VIEW2
-- 2008/10/27 Y.Kawano Mod Start
--                ,xxcmn_item_categories4_v         xic4v1  -- OPM�i�ڃJ�e�S���������VIEW4
                ,xxcmn_item_categories5_v         xic5v1  -- OPM�i�ڃJ�e�S���������VIEW5
-- 2008/10/27 Y.Kawano Mod End
                ,xxwsh_ship_method2_v             xsm2v             -- �z���敪���VIEW2
                ,fnd_user                         fu                -- ���[�U�[�}�X�^
                ,per_all_people_f                 papf              -- �]�ƈ��e�[�u��
--
      -------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      -------------------------------------------------------------------------------
      WHERE
      -------------------------------------------------------------------------------
      -- �o�Ɍ`��
                xoha.order_type_id                =   xott2v.transaction_type_id
      AND       xott2v.shipping_shikyu_class      =   lc_shikyu_cls_shukka_irai -- �o�׈˗�
      AND       xott2v.order_category_code        <>  lc_category_return        -- �ԕi(�󒍂̂�)
      -------------------------------------------------------------------------------
      AND       xoha.req_status                   >=  lc_status_shimezumi       -- ���ߍς݈ȏ�
      AND       xoha.req_status                   <>  lc_status_torikeshi       -- ������܂܂Ȃ�
-- 2008/10/27 Y.Kawano Add Start #62
      AND       xoha.schedule_ship_date           IS NOT NULL            -- �w���Ȃ����ёΏۊO
-- 2008/10/27 Y.Kawano Add End   #62
      -------------------------------------------------------------------------------
      -- �o�Ɍ����
      -------------------------------------------------------------------------------
      AND (
            (xil2v.distribution_block = in_block_1)
          OR
            (xil2v.distribution_block = in_block_2)
          OR
            (xil2v.distribution_block = in_block_3)
          OR
            (xoha.deliver_from        = in_delivery_origin)
          OR
            (
              (in_block_1 IS NULL) AND (in_block_2 IS NULL) 
              AND (in_block_3 IS NULL) AND (in_delivery_origin IS NULL)
            )
      )
      AND       (in_delivery_day IS NULL
        OR        xoha.schedule_ship_date         =   in_delivery_day)      -- �o�ɓ��͕K�{
      AND       (in_delivery_no IS NULL
        OR        xoha.delivery_no                =   in_delivery_no)
      AND       (in_delivery_form IS NULL
        OR        xott2v.transaction_type_id       =  in_delivery_form)
      AND       (in_jurisdiction_base IS NULL
        OR        xoha.head_sales_branch          =   in_jurisdiction_base)
      AND       (in_addre_delivery_dest IS NULL
        OR        xoha.deliver_to                 =   in_addre_delivery_dest)
      AND       (in_request_movement_no IS NULL
        OR        xoha.request_no                 =   in_request_movement_no)
      -------------------------------------------------------------------------------
      -- �^���Ǝ�(����)
      AND       xoha.career_id                    =   xc2v.party_id(+)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �z����^���ɐ�(����)
      AND       xoha.deliver_to_id                =   xcas2v.party_site_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �Ǌ����_(����)
      AND       xoha.head_sales_branch            =   xca2v.party_number
      -------------------------------------------------------------------------------
      AND       xoha.latest_external_flag         =   'Y'
      AND       fu.user_id                        =   FND_GLOBAL.USER_ID
      AND       papf.person_id                    =   fu.employee_id
      AND       (
      -------------------------------------------------------------------------------
      -- �����q�ɂ̏ꍇ
      -------------------------------------------------------------------------------
                  (
                    papf.attribute3               =   lc_employee_division_inside
                  OR
                    papf.attribute3            IS  NULL
                  )
      -------------------------------------------------------------------------------
      -- �O���q�ɂ̏ꍇ
      -------------------------------------------------------------------------------
                OR
                  (
                    (
                      -- attribute3(�]�ƈ��敪) �P�F�����A�Q�F�O��
                      papf.attribute3             =   lc_employee_division_outside
                    )
                  AND
                    (
                      -- �m��ʒm��
                      xoha.notif_status           =   lc_fixa_notif_end
                    )
                  )
                )
      -------------------------------------------------------------------------------
      -- �󒍖��׃A�h�I��
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �i��(�R�[�h)
      AND       xoha.order_header_id              =   xola.order_header_id
      AND       xola.delete_flag                  <>  lc_delete_flag
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�i�ڃ}�X�^
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �i��(����)
      AND       xola.shipping_inventory_item_id   =   xim2v1.inventory_item_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ����
      -- ���v��(���גP��)
      -- ���v��_�P��(���גP��)
-- 2008/10/27 Y.Kawano Mod Start #183
--      AND       xim2v1.item_id                    =   xic4v1.item_id
      AND       xim2v1.item_id                    =   xic5v1.item_id
-- 2008/10/27 Y.Kawano Mod End   #183
      AND       (in_commodity_div IS NULL
-- 2008/10/27 Y.Kawano Mod Start #183
--        OR        xic4v1.prod_class_code          =   in_commodity_div)
        OR        xic5v1.prod_class_code          =   in_commodity_div)
-- 2008/10/27 Y.Kawano Mod End   #183
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ�}�X�^
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �o�Ɍ�(����)
      AND       xoha.deliver_from_id              =   xil2v.inventory_location_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �ړ����b�g�ڍ�(�A�h�I��)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ���b�gNo
      AND       xola.order_line_id                =   xmldt.mov_line_id(+)
      AND       xmldt.document_type_code(+)       =   lc_doc_type_shukka_irai -- �o�׈˗�
      AND       xmldt.record_type_code(+)         =   lc_record_type_shizi    -- �w��
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ������
      -- �ܖ�����
      -- �ŗL�L��
      AND       xmldt.lot_id                      =   ilm.lot_id(+)
      AND       xmldt.item_id                     =   ilm.item_id(+)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �A�h�I���}�X�^�K�p��
      -------------------------------------------------------------------------------
      AND       xcas2v.start_date_active          <=  xoha.schedule_ship_date
      AND       ((xcas2v.end_date_active IS NULL)
        OR        (xcas2v.end_date_active         >=  xoha.schedule_ship_date))
--
      AND       xca2v.start_date_active           <=  xoha.schedule_ship_date
      AND       ((xca2v.end_date_active IS NULL)
        OR        (xca2v.end_date_active          >=  xoha.schedule_ship_date))
--
      AND       ((xc2v.start_date_active IS NULL)
        OR        (xc2v.start_date_active         <=  xoha.schedule_ship_date))
      AND       ((xc2v.end_date_active IS NULL)
        OR        (xc2v.end_date_active           >=  xoha.schedule_ship_date))
--
      AND       xim2v1.start_date_active          <=  xoha.schedule_ship_date
      AND       ((xim2v1.end_date_active IS NULL)
        OR        (xim2v1.end_date_active         >=  xoha.schedule_ship_date))
      -------------------------------------------------------------------------------
      -- �z���敪���VIEW2
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �z���敪(����)
      AND       xoha.shipping_method_code         =   xsm2v.ship_method_code(+)  -- 6/23 �O�������ǉ�
      -------------------------------------------------------------------------------
--
      ORDER BY
                 deliver_from         ASC
                ,schedule_ship_date   ASC
                ,delivery_no          ASC
                ,request_no           ASC
                ,shipping_item_code   ASC
                ,lot_no               ASC ;
--
    ------------------------------------------------------------------------
    -- �ړ��̏ꍇ
    ------------------------------------------------------------------------
    CURSOR cur_main_data2
      (
         in_block_1               VARCHAR2
        ,in_block_2               VARCHAR2
        ,in_block_3               VARCHAR2
        ,in_delivery_origin       VARCHAR2
        ,in_delivery_day          VARCHAR2
        ,in_delivery_no           VARCHAR2
        ,in_addre_delivery_dest   VARCHAR2
        ,in_request_movement_no   VARCHAR2
        ,in_commodity_div         VARCHAR2
      )
    IS
      SELECT
                 '�ړ�'                           AS gyoumu_shubetsu        -- �Ɩ����
                ,xmrih.delivery_no                AS delivery_no            -- �z��No
                ,xmrih.shipped_locat_code         AS shipped_locat_code     -- �o�Ɍ�(�R�[�h)
                ,xil2v1.description               AS description1           -- �o�Ɍ�(����)
                ,xmrih.freight_carrier_code       AS freight_carrier_code   -- �^���Ǝ�(�R�[�h)
                ,xc2v.party_short_name            AS party_short_name       -- �^���Ǝ�(����)
                ,xmrih.mov_num                    AS mov_num                -- �˗�No�^�ړ�No
                ,''                               AS shukkokeitai           -- �o�Ɍ`��
                ,xmrih.ship_to_locat_code         AS ship_to_locat_code     -- �z����^���ɐ�(����)
                ,xil2v2.description               AS description2           -- �z����^���ɐ�(����)
                ,xmrih.shipping_method_code       AS shipping_method_code   -- �z���敪(�R�[�h)
                ,xsm2v.ship_method_meaning        AS ship_method_meaning    -- �z���敪(����)
                ,''                               AS kankatsu_kyoten_code   -- �Ǌ����_(�R�[�h)
                ,''                               AS kankatsu_kyoten_name   -- �Ǌ����_(����)
                ,xmrih.schedule_ship_date         AS schedule_ship_date     -- �o�ɓ�
                ,xmrih.schedule_arrival_date      AS schedule_arrival_date  -- ����
                ,xmrih.arrival_time_from          AS arrival_time_from      -- ���Ԏw��From
                ,xmrih.arrival_time_to            AS arrival_time_to        -- ���Ԏw��To
                ,xmrih.description                AS desc_name              -- �E�v
                ,xmrih.batch_no                   AS batch_no               -- ��zNo
                ,xmril.item_code                  AS item_code              -- �i��(�R�[�h)
                ,xim2v1.item_short_name           AS item_short_name        -- �i��(����)
                ,xmldt.lot_no                     AS lot_no                 -- ���b�gNo
                ,ilm.attribute1                   AS attribute1             -- ������
                ,ilm.attribute3                   AS attribute3             -- �ܖ�����
                ,ilm.attribute2                   AS attribute2             -- �ŗL�L��
                ,CASE
                  -- ���i�̏ꍇ
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN ((xic4v1.item_class_code = lc_code_seihin) 
                  WHEN ((xic5v1.item_class_code = lc_code_seihin) 
-- 2008/10/27 Y.Kawano Mod End   #183
                        AND 
                        (ilm.attribute6 IS NOT NULL)) THEN xim2v1.num_of_cases
                  -- ���̑��̕i�ڂ̏ꍇ
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN (((xic4v1.item_class_code = lc_code_genryou) 
--                          OR  
--                         (xic4v1.item_class_code = lc_code_hanseihin))
                  WHEN (((xic5v1.item_class_code = lc_code_genryou) 
                          OR  
                         (xic5v1.item_class_code = lc_code_hanseihin))
-- 2008/10/27 Y.Kawano Mod End   #183
                        AND (ilm.attribute6 IS NOT NULL)) THEN TO_CHAR(TRUNC(ilm.attribute6))
                  -- �݌ɓ������ݒ肳��Ă��Ȃ�,���ޑ�,���b�g�Ǘ����Ă��Ȃ��ꍇ
                  WHEN ( ilm.attribute6 IS NULL ) THEN TO_CHAR(TRUNC(xim2v1.frequent_qty))
                END                               AS qty            -- ����
                ,CASE
                  WHEN  xmldt.mov_line_id IS NULL THEN
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xmril.instruct_qty / TO_NUMBER(
                                                      CASE WHEN xim2v1.num_of_cases > 0
                                                              THEN  xim2v1.num_of_cases
                                                           ELSE TO_CHAR(1)
                                                      END)
                      ELSE
                        xmril.instruct_qty
                    END
                  ELSE
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xmldt.actual_quantity / TO_NUMBER(
                                                        CASE  WHEN  xim2v1.num_of_cases > 0
                                                                THEN  xim2v1.num_of_cases
                                                              ELSE  TO_CHAR(1)
                                                        END)
                      ELSE
                        xmldt.actual_quantity
                    END
                END                               AS sum_quantity   -- ���v��(���גP��)
                ,CASE
                  WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #32,#183
--                  AND   xic4v1.item_class_code  = lc_code_seihin THEN
                  AND   xic5v1.item_class_code  = lc_code_seihin
                  AND   xim2v1.num_of_cases > '0'  THEN
-- 2008/10/27 Y.Kawano Mod End   #32,#183
                    xim2v1.conv_unit
                  ELSE
                    xim2v1.item_um
                END                               AS sum_item_um    -- ���v��_�P��(���גP��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xmrih.sum_weight + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- ���v�d��(���גP��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xmrih.sum_capacity + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- ���v�e��(���גP��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xmrih.sum_weight + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- �˗��d��(�˗����v�P��)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 �ǉ�
                    xmrih.sum_capacity + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- �˗��e��(�˗����v�P��)
-- 2008/07/07 A.Shiina v1.3 ADD Start
                ,xmrih.freight_charge_class       AS freight_charge_code    -- �^���敪
                ,xc2v.complusion_output_code      AS complusion_output_kbn  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.3 ADD End
--
      FROM
                 xxinv_mov_req_instr_headers      xmrih   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                ,xxinv_mov_req_instr_lines        xmril   -- �ړ��˗�/�w������(�A�h�I��)
                ,xxcmn_item_locations2_v          xil2v1  -- OPM�ۊǏꏊ���VIEW2(FROM)
                ,xxcmn_item_locations2_v          xil2v2  -- OPM�ۊǏꏊ���VIEW2(TO)
                ,xxcmn_carriers2_v                xc2v    -- �^���Ǝҏ��VIEW2
                ,xxinv_mov_lot_details            xmldt   -- �ړ����b�g�ڍ�(�A�h�I��)
                ,ic_lots_mst                      ilm     -- OPM���b�g�}�X�^
                ,xxcmn_item_mst2_v                xim2v1  -- OPM�i�ڏ��VIEW2
-- 2008/10/27 Y.Kawano Mod Start
--                ,xxcmn_item_categories4_v         xic4v1  -- OPM�i�ڃJ�e�S���������VIEW4
                ,xxcmn_item_categories5_v         xic5v1  -- OPM�i�ڃJ�e�S���������VIEW5
-- 2008/10/27 Y.Kawano Mod End
                ,xxwsh_ship_method2_v             xsm2v   -- �z���敪���VIEW2
                ,fnd_user                         fu      -- ���[�U�[�}�X�^
                ,xxpo_per_all_people_f2_v         papf    -- �]�ƈ����VIEW2
--
      -------------------------------------------------------------------------------
      -- �ړ��˗�/�w���w�b�_(�A�h�I��)
      -------------------------------------------------------------------------------
      WHERE
                xmrih.mov_type                    <> lc_mov_type_sekisou_nashi  -- �ϑ�����
      AND       xmrih.status                      >= lc_status_irai_zumi        -- �˗��ψȏ�
      AND       xmrih.status                      <> lc_status_torikeshi        -- ������܂܂Ȃ�
-- 2008/10/27 Y.Kawano Add Start #62
      AND     ((xmrih.no_instr_actual_class       IS NULL)
       OR      (xmrih.no_instr_actual_class       <>  gc_class_y)) -- �w���Ȃ����т͑ΏۊO
-- 2008/10/27 Y.Kawano Add End   #62
      -------------------------------------------------------------------------------
      -- �o�Ɍ����(From)
      -------------------------------------------------------------------------------
      AND (
            (xil2v1.distribution_block  = in_block_1)
          OR
            (xil2v1.distribution_block  = in_block_2)
          OR
            (xil2v1.distribution_block  = in_block_3)
          OR
            (xmrih.shipped_locat_code   = in_delivery_origin)
          OR
            (
              (in_block_1 IS NULL) AND (in_block_2 IS NULL) 
              AND (in_block_3 IS NULL) AND (in_delivery_origin IS NULL)
            )
      )
      AND       (xmrih.schedule_ship_date IS NULL
        OR        xmrih.schedule_ship_date        =   in_delivery_day)      -- �o�ɓ��͕K�{
      AND       (in_delivery_no IS NULL
        OR        xmrih.delivery_no               =   in_delivery_no)
      AND       (in_addre_delivery_dest IS NULL
        OR        xmrih.ship_to_locat_code         =   in_addre_delivery_dest)
      AND       (in_request_movement_no IS NULL
        OR        xmrih.mov_num                   =   in_request_movement_no)
      -------------------------------------------------------------------------------
      -- �^���Ǝ�(����)
      AND       xmrih.career_id                   =   xc2v.party_id(+)
      -------------------------------------------------------------------------------
      AND       fu.user_id                        =   FND_GLOBAL.USER_ID
      AND       papf.person_id                    =   fu.employee_id
      AND       (
      -------------------------------------------------------------------------------
      -- �����q�ɂ̏ꍇ
      -------------------------------------------------------------------------------
                  (
                    papf.attribute3               =   lc_employee_division_inside
                  OR
                    papf.attribute3            IS  NULL
                  )
      -------------------------------------------------------------------------------
      -- �O���q�ɂ̏ꍇ
      -------------------------------------------------------------------------------
                OR
                  (
                    (
                      -- attribute3(�]�ƈ��敪) �P�F�����A�Q�F�O��
                      papf.attribute3             =   lc_employee_division_outside
                    )
                  AND
                    (
                      -- �m��ʒm��
                      xmrih.notif_status          =   lc_fixa_notif_end
                    )
                  )
                )
      -------------------------------------------------------------------------------
      -- �ړ��˗�/�w���w�b�_(�A�h�I��)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �i��(�R�[�h)
      AND       xmrih.mov_hdr_id                  =   xmril.mov_hdr_id
      AND       xmril.delete_flg                  <>  lc_delete_flag
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�i�ڃ}�X�^
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �i��(����)
      -- ����
      -- ���v��_�P��(���גP��)
      AND       xmril.item_id                     =   xim2v1.item_id
-- 2008/10/27 Y.Kawano Mod Start #183
--      AND       xim2v1.item_id                    =   xic4v1.item_id
      AND       xim2v1.item_id                    =   xic5v1.item_id
-- 2008/10/27 Y.Kawano Mod End   #183
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ���i�敪
      AND       (in_commodity_div IS NULL
-- 2008/10/27 Y.Kawano Mod Start #183
--        OR        xic4v1.prod_class_code          =   in_commodity_div)
        OR        xic5v1.prod_class_code          =   in_commodity_div)
-- 2008/10/27 Y.Kawano Mod End   #183
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ�}�X�^(From)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �o�Ɍ�(����)
      AND       xmrih.shipped_locat_id            =   xil2v1.inventory_location_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ�}�X�^(To)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �z����^���ɐ�(����)
      AND       xmrih.ship_to_locat_id            =   xil2v2.inventory_location_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM���b�g�}�X�^
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ���b�gNo
      -- ���v��(���גP��)
      AND       xmril.mov_line_id                 =   xmldt.mov_line_id(+)
      AND       xmldt.document_type_code(+)       =   lc_doc_type_idou      -- �ړ�
      AND       xmldt.record_type_code(+)         =   lc_record_type_shizi  -- �w��
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ������
      -- �ܖ�����
      -- �ŗL�L��
      AND       xmldt.lot_id                      =   ilm.lot_id(+)
      AND       xmldt.item_id                     =   ilm.item_id(+)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �A�h�I���}�X�^�K�p��
      -------------------------------------------------------------------------------
      AND       ((xc2v.start_date_active IS NULL)
        OR        (xc2v.start_date_active         <=  xmrih.schedule_ship_date))
      AND       ((xc2v.end_date_active IS NULL)
        OR        (xc2v.end_date_active           >=  xmrih.schedule_ship_date))
--
      AND       xim2v1.start_date_active          <=  xmrih.schedule_ship_date
      AND       ((xim2v1.end_date_active IS NULL)
        OR        (xim2v1.end_date_active         >=  xmrih.schedule_ship_date))
      -------------------------------------------------------------------------------
      -- �z���敪���VIEW2
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- �z���敪(����)
      AND       xmrih.shipping_method_code        =   xsm2v.ship_method_code(+)  -- 6/23 �O�������ǉ�
      -------------------------------------------------------------------------------
--
      ORDER BY
                 shipped_locat_code   ASC
                ,schedule_ship_date   ASC
                ,delivery_no          ASC
                ,mov_num              ASC
                ,item_code            ASC
                ,lot_no               ASC ;
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
    -- �f�[�^���o
    -- ====================================================
    IF ( ir_param.iv_business_type = gc_code_shukka ) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_main_data1
        (
           ir_param.iv_block_1
          ,ir_param.iv_block_2
          ,ir_param.iv_block_3
          ,ir_param.iv_delivery_origin
          ,ir_param.iv_delivery_day
          ,ir_param.iv_delivery_no
          ,ir_param.iv_delivery_form
          ,ir_param.iv_jurisdiction_base
          ,ir_param.iv_addre_delivery_dest
          ,ir_param.iv_request_movement_no
          ,ir_param.iv_commodity_div
        ) ;
      -- �o���N�t�F�b�`
      FETCH cur_main_data1 BULK COLLECT INTO ot_data_rec ;
      -- �J�[�\���N���[�Y
      CLOSE cur_main_data1 ;
      -- ���[�o�͖����Z�b�g
      gv_out_char_title :=  gc_out_char_title_shukko;
    ELSE
      -- �J�[�\���I�[�v��
      OPEN cur_main_data2
        (
           ir_param.iv_block_1
          ,ir_param.iv_block_2
          ,ir_param.iv_block_3
          ,ir_param.iv_delivery_origin
          ,ir_param.iv_delivery_day
          ,ir_param.iv_delivery_no
          ,ir_param.iv_addre_delivery_dest
          ,ir_param.iv_request_movement_no
          ,ir_param.iv_commodity_div
        ) ;
      -- �o���N�t�F�b�`
      FETCH cur_main_data2 BULK COLLECT INTO ot_data_rec ;
      -- �J�[�\���N���[�Y
      CLOSE cur_main_data2 ;
      -- ���[�o�͖����Z�b�g
      gv_out_char_title :=  gc_out_char_title_idou;
    END IF ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( cur_main_data1%ISOPEN ) THEN
        CLOSE cur_main_data1 ;
      END IF ;
      IF ( cur_main_data2%ISOPEN ) THEN
        CLOSE cur_main_data2 ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( cur_main_data1%ISOPEN ) THEN
        CLOSE cur_main_data1 ;
      END IF ;
      IF ( cur_main_data2%ISOPEN ) THEN
        CLOSE cur_main_data2 ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( cur_main_data1%ISOPEN ) THEN
        CLOSE cur_main_data1 ;
      END IF ;
      IF ( cur_main_data2%ISOPEN ) THEN
        CLOSE cur_main_data2 ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(H-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param          IN      rec_param_data  -- 01.���R�[�h  �F�p�����[�^
     ,iox_xml_data      IN OUT  NOCOPY XML_DATA 
     ,ov_errbuf         OUT     VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT     VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT     VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- ���z�v�Z�p
    lv_juuryou_amount       NUMBER      := 0 ;                        -- �y�˗��d�ʁz
    lv_youseki_amount       NUMBER      := 0 ;                        -- �y�˗��e�ρz
--
    -- �u���C�N�L�[
    lv_request_no           xxwsh_order_headers_all.request_no%TYPE ; -- �˗�No�^�ړ�No
    lv_header_disp_flg      BOOLEAN ;
    lv_detail_end_disp_flg  BOOLEAN ;
    lv_party_site_name1     VARCHAR2(31);
    lv_party_site_name2     VARCHAR2(30);
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;                               -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
    -- =====================================================
    -- �ϐ������ݒ�
    -- =====================================================
    gt_xml_data_table.DELETE ;
--
    -- =====================================================
    -- ���׃f�[�^�擾(H-3)
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
--
    -- �u���C�N�L�[�̏�����
    IF ( gt_main_data.COUNT > 0 ) THEN
      lv_request_no         :=  gt_main_data(1).request_no ;
    ELSE
      lv_request_no         :=  NULL ;
    END IF ;
    lv_header_disp_flg      :=  TRUE ;
    lv_detail_end_disp_flg  :=  TRUE ;
--
    -- -----------------------------------------------------
    -- �f�[�^�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
--
    -- -----------------------------------------------------
    -- �`�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prcsub_set_xml_data('lg_denpyo_info') ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- �w�b�_�[�o�̓t���O
      IF ( lv_header_disp_flg = TRUE ) THEN
--
        -- -----------------------------------------------------
        -- �w�b�_�[�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prcsub_set_xml_data('g_denpyo') ;
--
        -- ���[�^�C�g��
        prcsub_set_xml_data('title', gv_out_char_title || gc_msg_shizisyo) ;
        -- ���[ID
        prcsub_set_xml_data('tyohyo_id', gc_report_id) ;
        -- �o�͓��t
        prcsub_set_xml_data('shuturyoku_hiduke', TO_CHAR(gd_exec_date, gc_char_dt_format)) ;
        -- �S���i�����j
        prcsub_set_xml_data('tantou_busho', gv_department_code) ;
        -- �S���i�����j
        prcsub_set_xml_data('tantou_name', gv_department_name) ;
--
        -- �z����/���ɐ�i���́j��s�o�͔���
        IF ( LENGTH(SUBSTRB(gt_main_data(i).party_site_name, 29, 2)) = 1 ) THEN
          lv_party_site_name1 := substrb(gt_main_data(i).party_site_name, 1, 30) ;
          lv_party_site_name2 := substrb(gt_main_data(i).party_site_name, 31) ;
        ELSE
          IF (length(substrb(gt_main_data(i).party_site_name, 30, 2)) = 1 ) then
            lv_party_site_name1 := substrb(gt_main_data(i).party_site_name, 1, 31) ;
            lv_party_site_name2 := substrb(gt_main_data(i).party_site_name, 32) ;
          ELSE
            lv_party_site_name1 := substrb(gt_main_data(i).party_site_name, 1, 30) ;
            lv_party_site_name2 := substrb(gt_main_data(i).party_site_name, 31) ;
          END IF;
        END IF;
        --
        -- �Ɩ���� 
        prcsub_set_xml_data('gyoumu_shubetsu', gt_main_data(i).gyoumu_shubetsu) ;
        -- �z��No.
        prcsub_set_xml_data('haisou_no', gt_main_data(i).delivery_no) ;
        -- �o�Ɍ��i�R�[�h�j 
        prcsub_set_xml_data('shukko_saki_code', gt_main_data(i).deliver_from) ;
        -- �o�Ɍ��i���́j 
        prcsub_set_xml_data('shukko_saki_name', gt_main_data(i).description) ;
-- 2008/07/03 A.Shiina v1.3 Update Start
       IF  ((gt_main_data(i).freight_charge_code  = '1')
        OR (gt_main_data(i).complusion_output_kbn = '1')) THEN
        -- �^���Ǝҁi�R�[�h�j 
        prcsub_set_xml_data('unsou_gyousha_code', gt_main_data(i).freight_carrier_code) ;
        -- �^���Ǝҁi���́j 
        prcsub_set_xml_data('unsou_gyousha_name', gt_main_data(i).party_short_name1) ;
       END IF;
-- 2008/07/03 A.Shiina v1.3 Update End
        -- �˗�No/�ړ�No
        prcsub_set_xml_data('irai_idou_no', gt_main_data(i).request_no) ;
        -- �o�Ɍ`�� 
        prcsub_set_xml_data('shukko_keitai'
                          , gt_main_data(i).transaction_type_name
                          , gc_tag_type_data) ;
        -- �z����/���ɐ�i�R�[�h�j 
        prcsub_set_xml_data('haisou_shukko_saki_code', gt_main_data(i).deliver_to) ;
        -- �z����/���ɐ�i���̂P�j 
        prcsub_set_xml_data('haisou_shukko_saki_name1', lv_party_site_name1) ;
        -- �z����/���ɐ�i���̂Q�j
        prcsub_set_xml_data('haisou_shukko_saki_name2', lv_party_site_name2) ;
        -- �z���敪�i�R�[�h�j 
        prcsub_set_xml_data('haisou_kubun_code', gt_main_data(i).shipping_method_code) ;
        -- �z���敪�i���́j 
        prcsub_set_xml_data('haisou_kubun_name', gt_main_data(i).ship_method_meaning) ;
        -- �Ǌ����_�i�R�[�h�j 
        prcsub_set_xml_data('kankatsu_kyoten_code'
                           , gt_main_data(i).head_sales_branch
                           , gc_tag_type_data) ;
        -- �Ǌ����_�i���́j 
        prcsub_set_xml_data('kankatsu_kyoten_name', gt_main_data(i).party_name, gc_tag_type_data) ;
        -- �o�ɓ� 
        prcsub_set_xml_data('shukkobi', TO_CHAR(gt_main_data(i).schedule_ship_date
                                              , gc_char_d_format)) ;
        -- ���� 
        prcsub_set_xml_data('tyakubi', TO_CHAR(gt_main_data(i).schedule_arrival_date
                                             , gc_char_d_format)) ;
        -- ���Ԏw��iFrom�j 
        prcsub_set_xml_data('jikan_shitei_from', TO_CHAR(TO_DATE(gt_main_data(i).arrival_time_from
                                                               , lc_date_jikanshitei_format)
                                                       , lc_date_jikanshitei_format)) ;
        -- ���Ԏw��iTo�j 
        prcsub_set_xml_data('jikan_shitei_to', TO_CHAR(TO_DATE(gt_main_data(i).arrival_time_to
                                                             , lc_date_jikanshitei_format)
                                                     , lc_date_jikanshitei_format)) ;
--
        -- ��zNo�i���x���A�l�j���ړ����̂ݒ��[�ɏo�͂����B
        IF ( ir_param.iv_business_type <> gc_code_shukka ) THEN
          -- ��zNo�i���x���j���ړ����̂݁w��zNo�x������ 
          prcsub_set_xml_data('tehai_no_label', gc_tehai_label, gc_tag_type_data) ;
          -- ��zNo�i�l�j���ړ����̂ݒl������ 
          prcsub_set_xml_data('tehai_no_value', gt_main_data(i).batch_no, gc_tag_type_data) ;
        END IF ;
--
        -- �E�v 
        prcsub_set_xml_data('tekiyou', gt_main_data(i).shipping_instructions) ;
--
        -- -----------------------------------------------------
        -- ���ׂk�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prcsub_set_xml_data('lg_denpyo_detail') ;
--
      END IF ;
--
      -- -----------------------------------------------------
      -- ���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      prcsub_set_xml_data('g_denpyo_detail') ;
--
      prcsub_set_xml_data('hinmoku_code', gt_main_data(i).shipping_item_code) ; -- �i�ځi�R�[�h�j
      prcsub_set_xml_data('hinmoku_name', gt_main_data(i).item_short_name) ;    -- �i�ځi���́j
      prcsub_set_xml_data('rotto_no', gt_main_data(i).lot_no) ;                 -- ���b�gNo
      prcsub_set_xml_data('seizoubi', TO_CHAR(TO_DATE(gt_main_data(i).attribute1
                                                    , gc_char_d_format)
                                            , gc_char_d_format)) ;              -- ������
      prcsub_set_xml_data('shoumikigen', TO_CHAR(TO_DATE(gt_main_data(i).attribute3
                                                       , gc_char_d_format)
                                               , gc_char_d_format)) ;           -- �ܖ�����
      prcsub_set_xml_data('koyuukigou', gt_main_data(i).attribute2) ;           -- �ŗL�L��
      prcsub_set_xml_data('iri_suu', gt_main_data(i).qty) ;                     -- ����
      prcsub_set_xml_data('goukei_suu', gt_main_data(i).sum_quantity) ;         -- ���v��
      prcsub_set_xml_data('goukei_suu_unit', gt_main_data(i).sum_item_um) ;     -- ���v���i�P�ʁj
--
      -- -----------------------------------------------------
      -- ���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      prcsub_set_xml_data('/g_denpyo_detail') ;
--
      -- �u���C�N�L�[�̃`�F�b�N�ƁA�ŏI���׍s�̃`�F�b�N
      IF ( i < gt_main_data.COUNT ) THEN
--
        IF ( lv_request_no <> gt_main_data(i + 1).request_no ) THEN
          -- �u���C�N�L�[�̍X�V
          lv_request_no           := gt_main_data(i + 1).request_no ;
          -- �w�b�_�[���o�͂���B
          lv_header_disp_flg      := TRUE ;
          -- ���׍ŏI�s���o�͂���B
          lv_detail_end_disp_flg  := TRUE ;
        ELSE
          -- �w�b�_�[���o�͂��Ȃ��B
          lv_header_disp_flg      := FALSE ;
          -- ���׍ŏI�s���o�͂��Ȃ��B
          lv_detail_end_disp_flg  := FALSE ;
        END IF ;
--
      ELSE
          -- �w�b�_�[���o�͂���B
          lv_header_disp_flg      := TRUE ;
          -- ���׍ŏI�s���o�͂���B
          lv_detail_end_disp_flg  := TRUE ;
      END IF ;
--
      -- ���׍ŏI�s�o�̓t���O
      IF ( lv_detail_end_disp_flg = TRUE ) THEN
--
-- 2008/07/03 MOD START NAKADA ST�s��Ή�No412 �d�ʗe�ς̏������ʐ؂�グ
        -- �y�˗��d�ʁz
        prcsub_set_xml_data('irai_juuryou', CEIL(TRUNC(gt_main_data(i).sum_weight_irai,1))) ;
-- 2008/07/03 MOD END   NAKADA
--
        -- �y�˗��d�ʁz�i�P�ʁj
        prcsub_set_xml_data('irai_juuryou_unit', gv_uom_weight) ;
--
-- 2008/07/03 MOD START NAKADA ST�s��Ή�No412 �d�ʗe�ς̏������ʐ؂�グ
        -- �y�˗��e�ρz
        prcsub_set_xml_data('irai_youseki', CEIL(TRUNC(gt_main_data(i).sum_capacity_irai,1))) ;
-- 2008/07/03 MOD END   NAKADA
--
        -- �y�˗��e�ρz�i�P�ʁj
        prcsub_set_xml_data('irai_youseki_unit', gv_uom_capacity) ;
--
        -- -----------------------------------------------------
        -- ���ׂk�f�I���^�O�o��
        -- -----------------------------------------------------
        prcsub_set_xml_data('/lg_denpyo_detail') ;
        -- -----------------------------------------------------
        -- �w�b�_�[�f�I���^�O�o��
        -- -----------------------------------------------------
        prcsub_set_xml_data('/g_denpyo') ;
--
      END IF ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    -- -----------------------------------------------------
    -- �`�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prcsub_set_xml_data('/lg_denpyo_info') ;
--
    -- -----------------------------------------------------
    -- �f�[�^�f�I���^�O�o��
    -- -----------------------------------------------------
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
       iv_business_type       IN    VARCHAR2      -- 01 : �Ɩ����
      ,iv_block_1             IN    VARCHAR2      -- 02 : �u���b�N�P
      ,iv_block_2             IN    VARCHAR2      -- 03 : �u���b�N�Q
      ,iv_block_3             IN    VARCHAR2      -- 04 : �u���b�N�R
      ,iv_delivery_origin     IN    VARCHAR2      -- 05 : �o�Ɍ�
      ,iv_delivery_day        IN    VARCHAR2      -- 06 : �o�ɓ�
      ,iv_delivery_no         IN    VARCHAR2      -- 07 : �z����
      ,iv_delivery_form       IN    VARCHAR2      -- 08 : �o�Ɍ`��
      ,iv_jurisdiction_base   IN    VARCHAR2      -- 09 : �Ǌ����_
      ,iv_addre_delivery_dest IN    VARCHAR2      -- 10 : �z����/���ɐ�
      ,iv_request_movement_no IN    VARCHAR2      -- 11 : �˗���/�ړ���
      ,iv_commodity_div       IN    VARCHAR2      -- 12 : ���i�敪
      ,ov_errbuf              OUT   VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             OUT   VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              OUT   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name CONSTANT  VARCHAR2(100) := 'submain' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf   VARCHAR2(5000) ;                        -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1) ;                           -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) ;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec          rec_param_data ;          -- �p�����[�^��n���p
--
    xml_data_table        XML_DATA;
    lv_xml_string         VARCHAR2(32000) ;
    ln_retcode            NUMBER ;
--
    lv_business_name      VARCHAR2(4);              -- �o�׋Ɩ����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gd_exec_date                      :=  SYSDATE ;               -- ���{��
--
    -- =====================================================
    -- �v���t�@�C���l�擾�A�S���ҏ�񒊏o(H-1,H-2)
    -- =====================================================
    prc_initialize
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    lr_param_rec.iv_business_type       :=  iv_business_type;       -- 01 : �Ɩ����
    lr_param_rec.iv_block_1             :=  iv_block_1;             -- 02 : �u���b�N�P
    lr_param_rec.iv_block_2             :=  iv_block_2;             -- 03 : �u���b�N�Q
    lr_param_rec.iv_block_3             :=  iv_block_3;             -- 04 : �u���b�N�R
    lr_param_rec.iv_delivery_origin     :=  iv_delivery_origin;     -- 05 : �o�Ɍ�
    -- 06 : �o�ɓ�
    lr_param_rec.iv_delivery_day        :=  FND_DATE.CANONICAL_TO_DATE( iv_delivery_day );
    lr_param_rec.iv_delivery_no         :=  iv_delivery_no;         -- 07 : �z����
    lr_param_rec.iv_delivery_form       :=  iv_delivery_form;       -- 08 : �o�Ɍ`��
    lr_param_rec.iv_jurisdiction_base   :=  iv_jurisdiction_base;   -- 09 : �Ǌ����_
    lr_param_rec.iv_addre_delivery_dest :=  iv_addre_delivery_dest; -- 10 : �z����/���ɐ�
    lr_param_rec.iv_request_movement_no :=  iv_request_movement_no; -- 11 : �˗���/�ړ���
    lr_param_rec.iv_commodity_div       :=  iv_commodity_div;       -- 12 : ���i�敪
--
    -- =====================================================
    -- �f�[�^�o��(H-4)
    -- =====================================================
    prc_create_xml_data
      (
        iox_xml_data      => xml_data_table
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��(H-4)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( ( lv_errmsg IS NOT NULL ) AND ( lv_retcode = gv_status_warn ) ) THEN
--
      -- �Ɩ���ʎ擾SQL
      BEGIN
        SELECT
          xlv1v1.meaning                AS meaning            -- �Ɩ����
        INTO
          lv_business_name
        FROM
          xxcmn_lookup_values_v         xlv1v1                -- �N�C�b�N�R�[�h���VIEW
        WHERE
          lr_param_rec.iv_business_type =   xlv1v1.lookup_code
        AND
          xlv1v1.lookup_type            =   gc_quick_code_gyoumushubetsu ;
      EXCEPTION
        WHEN  OTHERS  THEN
          lv_business_name  :=  '' ;
      END ;
--
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<g_denpyo>' ) ;
--
      -- ���[�^�C�g��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<title>' || gv_out_char_title || gc_msg_shizisyo ||
                                          '</title>' ) ;
      -- ���[ID
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tyohyo_id>' || gc_report_id ||
                                          '</tyohyo_id>' ) ;
      -- �o�͓��t
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<shuturyoku_hiduke>' 
        || TO_CHAR(gd_exec_date, gc_char_dt_format)
        || '</shuturyoku_hiduke>' ) ;
      -- �S���i�����j
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tantou_busho>' || gv_department_code ||
                                          '</tantou_busho>' ) ;
      -- �S���i�����j
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tantou_name>' || gv_department_name ||
                                          '</tantou_name>' ) ;
--
      -- ��zNo�i���x���A�l�j���ړ����̂ݒ��[�ɏo�͂����B
      IF ( lr_param_rec.iv_business_type <> gc_code_shukka ) THEN
        -- ��zNo�i���x���j���ړ����̂݁w��zNo�x������ 
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tehai_no_label>' || gc_tehai_label ||
                                            '</tehai_no_label>') ;
      END IF ;
--
      -- �Ɩ���� 
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<gyoumu_shubetsu>' || lv_business_name || 
                                          '</gyoumu_shubetsu>' ) ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<msg>' || lv_errmsg || 
                                          '</msg>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</g_denpyo>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      --XML�f�[�^���o��
      <<xml_loop>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_loop ;
--
    END IF ;
--
    --XML�f�[�^�폜
    gt_xml_data_table.DELETE ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
       errbuf                   OUT   VARCHAR2          -- �G���[���b�Z�[�W
      ,retcode                  OUT   VARCHAR2          -- �G���[�R�[�h
      ,iv_business_type         IN    VARCHAR2          -- 01 : �Ɩ����
      ,iv_block_1               IN    VARCHAR2          -- 02 : �u���b�N�P
      ,iv_block_2               IN    VARCHAR2          -- 03 : �u���b�N�Q
      ,iv_block_3               IN    VARCHAR2          -- 04 : �u���b�N�R
      ,iv_delivery_origin       IN    VARCHAR2          -- 05 : �o�Ɍ�
      ,iv_delivery_day          IN    VARCHAR2          -- 06 : �o�ɓ�
      ,iv_delivery_no           IN    VARCHAR2          -- 07 : �z����
      ,iv_delivery_form         IN    VARCHAR2          -- 08 : �o�Ɍ`��
      ,iv_jurisdiction_base     IN    VARCHAR2          -- 09 : �Ǌ����_
      ,iv_addre_delivery_dest   IN    VARCHAR2          -- 10 : �z����/���ɐ�
      ,iv_request_movement_no   IN    VARCHAR2          -- 11 : �˗���/�ړ���
      ,iv_commodity_div         IN    VARCHAR2          -- 12 : ���i�敪
  )
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name   CONSTANT  VARCHAR2(100)   := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_business_type        => iv_business_type         -- 01 : �Ɩ����
       ,iv_block_1              => iv_block_1               -- 02 : �u���b�N�P
       ,iv_block_2              => iv_block_2               -- 03 : �u���b�N�Q
       ,iv_block_3              => iv_block_3               -- 04 : �u���b�N�R
       ,iv_delivery_origin      => iv_delivery_origin       -- 05 : �o�Ɍ�
       ,iv_delivery_day         => iv_delivery_day          -- 06 : �o�ɓ�
       ,iv_delivery_no          => iv_delivery_no           -- 07 : �z����
       ,iv_delivery_form        => iv_delivery_form         -- 08 : �o�Ɍ`��
       ,iv_jurisdiction_base    => iv_jurisdiction_base     -- 09 : �Ǌ����_
       ,iv_addre_delivery_dest  => iv_addre_delivery_dest   -- 10 : �z����/���ɐ�
       ,iv_request_movement_no  => iv_request_movement_no   -- 11 : �˗���/�ړ���
       ,iv_commodity_div        => iv_commodity_div         -- 12 : ���i�敪
       ,ov_errbuf               => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode              => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg               => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh620008c;
/