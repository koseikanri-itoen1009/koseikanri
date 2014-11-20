CREATE OR REPLACE PACKAGE BODY xxpo440006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440006(spec)
 * Description      : �����w����
 * MD.050/070       : �����w����(T_MD050_BPO_444)
 *                    �����w����T_MD070_BPO_44N)
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_sql              PROCEDURE : �f�[�^�擾�r�p�k���� (N-2)
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW (N-3)
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/21    1.0   Yusuke Tabata   �V�K�쐬
 *  2008/05/20    1.1   Yusuke Tabata   �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/06/03    1.2   Yohei  Takayama �����e�X�g�s����O#440_47
 *  2008/06/04    1.3 Yasuhisa Yamamoto �����e�X�g�s����O#440_48,#440_55
 *  2008/06/07    1.4   Yohei  Takayama �����e�X�g�s����O#440_67
 *  2008/07/02    1.5   Satoshi Yunba   �֑������Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
-- 2008/06/04 UPD START Y.Yamamoto
--  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440006C' ;      -- �p�b�P�[�W��
--  gc_report_id            CONSTANT VARCHAR2(20) := 'xxpo440006T' ;      -- ���[ID
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXPO440006C' ;      -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440006T' ;      -- ���[ID
-- 2008/06/04 UPD END Y.Yamamoto
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122';   -- �f�[�^�O�����b�Z�[�W
  gc_err_code_no_prof     CONSTANT VARCHAR2(15) := 'APP-XXPO-10005' ;   -- �v���t�@�C���擾�G���[
--
  ------------------------------
  -- �v���t�@�C����
  ------------------------------
  gc_prof_org_id          CONSTANT VARCHAR2(20) := 'ORG_ID' ;   -- �c�ƒP��
  gn_prof_org_id          oe_transaction_types_all.org_id%TYPE ;
--
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �󒍃J�e�S���F�󒍃J�e�S���R�[�h
  gc_order_cat_r          CONSTANT VARCHAR2(10) := 'RETURN' ; -- �ԕi
  -- �󒍃J�e�S���F�o�׎x���敪
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- �x���˗�
  -- �󒍃J�e�S���F�o�׎x���󕥃J�e�S��
  gc_sp_category_s        CONSTANT VARCHAR2(2)  := '05' ;   -- �L���o��
  -- �󒍃w�b�_�A�h�I���F�ŐV�t���O�iYesNo�敪�j
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- �󒍃w�b�_�A�h�I���F�X�e�[�^�X
  gc_req_status_s_cmpd    CONSTANT VARCHAR2(2)  := '07';    -- ��̍�
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99';    -- ���
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- �x���w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2)  := '10';    -- �w��
  -- �n�o�l�i�ڃ}�X�^�F���b�g�Ǘ��敪
  gc_lot_ctl_y            CONSTANT NUMBER(1)    := 1 ;      -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT NUMBER(1)    := 0 ;      -- ���b�g�Ǘ��Ȃ�
  -- �n�o�l�i�ڃJ�e�S���F�i�ڋ敪
  gc_item_div_prod        CONSTANT VARCHAR2(1)  := '5' ;    -- ���i
  ------------------------------
  -- ���̑�
  ------------------------------
  -- �ő���t
  gc_max_date_char  CONSTANT VARCHAR2(10) := '4712/12/31' ;
  -- ���t�}�X�N
  gc_date_mask      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b�}�X�N
  gc_date_mask_m    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD' ;            -- �N����(YYYY/MM/DD)�}�X�N
  gc_date_mask_s    CONSTANT VARCHAR2(10) := 'MM/DD' ;                 -- ����(MM/DD)�}�X�N
  -- �o��
  gc_tag_type_t     CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d     CONSTANT VARCHAR2(1)  := 'D' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      vendor_code          VARCHAR2(4)         -- 01 : �����
     ,deliver_to_code      VARCHAR2(4)         -- 02 : �z����
     ,design_item_code_01  VARCHAR2(7)         -- 03 : �����i�ڂP
     ,design_item_code_02  VARCHAR2(7)         -- 04 : �����i�ڂQ
     ,design_item_code_03  VARCHAR2(7)         -- 05 : �����i�ڂR
     ,date_from            VARCHAR2(10)        -- 06 : �o�ɓ�From
     ,date_to              VARCHAR2(10)        -- 07 : �o�ɓ�To
     ,design_no            VARCHAR2(10)        -- 08 : �����ԍ�
     ,security_div         VARCHAR2(1)         -- 09 : �L���Z�L�����e�B�敪
    ) ;
--
  -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl IS RECORD
    (
       vendor_code       xxcmn_vendors2_v.segment1%TYPE                     -- �����i�����R�[�h�j
      ,vendor_name       xxcmn_vendors2_v.vendor_full_name%TYPE             -- �����i����於�j
      ,deliver_to_code   xxcmn_vendor_sites2_v.vendor_site_code%TYPE        -- �z����i�z����R�[�h�j
      ,deliver_to_name   xxcmn_vendor_sites2_v.vendor_site_name%TYPE        -- �z����i�z���於�j
      ,design_item_code  xxcmn_item_mst2_v.item_no%TYPE                     -- �����i�ځi�����i�ڃR�[�h�j
      ,design_item_name  xxcmn_item_mst2_v.item_short_name%TYPE             -- �����i�ځi�����i�ږ��j
      ,design_date       xxcmn_item_categories4_v.item_class_code%TYPE      -- ������
      ,design_no         xxcmn_item_categories4_v.item_class_name%TYPE      -- �����ԍ�
      ,item_code         xxcmn_item_mst2_v.item_no%TYPE                     -- �i�ځi�i�ڃR�[�h�j
      ,item_name         xxcmn_item_mst2_v.item_short_name%TYPE             -- �i�ځi�i�ږ��j
      ,futai_code        xxwsh_order_lines_all.futai_code%TYPE              -- �t��
      ,lot_no            ic_lots_mst.lot_no%TYPE                            -- ���b�gNo
      ,maked_date        VARCHAR2(10)                                       -- ������(YYYY/MM/DD)
      ,limit_date        VARCHAR2(10)                                       -- �ܖ�����(YYYY/MM/DD)
      ,orgn_sign         ic_lots_mst.attribute2%TYPE                        -- �ŗL�L��
      ,entry_quant       xxcmn_item_mst2_v.frequent_qty%TYPE                -- ����
      ,quant             xxinv_mov_lot_details.actual_quantity%TYPE         -- ����
      ,unit              xxwsh_order_lines_all.uom_code%TYPE                -- �P��
      ,deliver_from_code xxcmn_item_locations2_V.segment1%TYPE              -- �o�ɑq��(�o�ɑq�ɃR�[�h)
      ,deliver_from_name xxcmn_item_locations2_V.description%TYPE           -- �o�ɑq��(�o�ɑq�ɖ�)
      ,dtl_desc          xxwsh_order_lines_all.line_description%TYPE        -- ���דE�v
      ,request_no        xxwsh_order_headers_all.request_no%TYPE            -- �˗�No
      ,arrival_date      VARCHAR2(5)                                        -- ���ɓ�(MM/DD)
    ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gn_data_cnt           NUMBER DEFAULT  0 ;         -- �����f�[�^�J�E���^
  gv_sql                VARCHAR2(32000);     -- �f�[�^�擾�p�r�p�k
--
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER DEFAULT  0 ;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  -- ���O�C�����[�U�[�h�c
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;
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
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ���[�U�[���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���[�U�[�f�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, gc_date_mask ) ;
--
    -- ====================================================
    -- ���[�U�[�f�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
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
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql(N-2)
   * Description      : �f�[�^�擾�r�p�k����
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_date_from  VARCHAR2(150)   ;
    lv_work_str   VARCHAR2(1500)  ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ��������
    -- ====================================================
    -- �p�����[�^DATE_FROM�����`
    lv_date_from :=  'FND_DATE.STRING_TO_DATE('
    || ''''  || gr_param.date_from  ||''''
    || ',''' || gc_date_mask ||''''
    || ')'
    ;
    -- ====================================================
    -- �r�d�k�d�b�s�吶��
    -- ====================================================
    lv_select := ' SELECT'
    || ' xvv.segment1                    AS vendor_code'       -- �����i�����R�[�h�j
    || ',xvv.vendor_full_name            AS vendor_name'       -- �����i����於�j
    || ',xvsv.vendor_site_code           AS deliver_to_code'   -- �z����i�z����R�[�h�j
    || ',xvsv.vendor_site_name           AS deliver_to_name'   -- �z����i�z���於�j
    || ',xim1.item_no                    AS design_item_code'  -- �����i�ځi�����i�ڃR�[�h�j
    -- 2008/06/30 UPD START Y.Takayama
    --|| ',xim1.item_desc1                 AS design_item_name'  -- �����i�ځi�����i�ږ��j
    || ',xim1.item_short_name            AS design_item_name'  -- �����i�ځi�����i�ږ��j
    -- 2008/06/30 UPD END   Y.Takayama
    || ',TO_CHAR(xoha.designated_production_date,'
    || '''' || gc_date_mask_m || ''' )   AS design_date'       -- ������
    || ',xoha.designated_branch_no       AS design_no'         -- �����ԍ�
    || ',xim2.item_no                    AS item_code'         -- �i�ځi�i�ڃR�[�h�j
    -- 2008/06/30 UPD START Y.Takayama
    --|| ',xim2.item_desc1                 AS item_name'         -- �i�ځi�i�ږ��j
    || ',xim2.item_short_name            AS item_name'         -- �i�ځi�i�ږ��j
    -- 2008/06/30 UPD END   Y.Takayama
    || ',xola.futai_code                 AS futai_code'        -- �t��
    -- ���b�g���o��:���b�g�Ǘ��i����
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.lot_no'
    || '   ELSE '
    || '     NULL'
    || ' END                           AS lot_no'             -- ���b�gNo
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute1)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS maked_date'         -- ������
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute3)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS limit_date'         -- �ܖ�����
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute2'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS orgn_sign'          -- �ŗL�L��
    -- �����o��:���b�g�Ǘ��i����
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute6'
    || '   ELSE'
    || '     xim2.frequent_qty'
    || ' END                           AS entry_quant'        -- ����
    || ' ,xmld.actual_quantity         AS quant'              -- ����
    || ',xola.uom_code                 AS unit'               -- �P��
    || ',xilv.segment1                 AS deliver_from_code'  -- �o�ɑq��(�o�ɑq�ɃR�[�h)
    || ',xilv.description              AS deliver_from_name'  -- �o�ɑq��(�o�ɑq�ɖ�)
    || ',xola.line_description         AS dtl_desc'           -- ���דE�v
    || ',xoha.request_no               AS request_no'         -- �˗�No
    || ',TO_CHAR(xoha.schedule_arrival_date,'
    || '''' || gc_date_mask_s || ''' ) AS arrival_date'       -- ���ɓ�(MM/DD)
    ;
--
    -- ====================================================
    -- �e�q�n�l�吶��
    -- ====================================================
    lv_from := ' FROM'
    || ' xxwsh_order_headers_all    xoha'   -- �󒍃w�b�_�A�h�I��
    || ',oe_transaction_types_all   otta'   -- �󒍃^�C�v
    || ',xxwsh_order_lines_all      xola'   -- �󒍖��׃A�h�I��
    || ',xxinv_mov_lot_details      xmld'   -- �ړ����b�g�ڍ׃A�h�I��
    || ',ic_lots_mst                 ilm'   -- OPM���b�g�}�X�^
    || ',xxcmn_item_mst2_v          xim1'   -- OPM�i�ڏ��View(�����i��)
    || ',xxcmn_item_mst2_v          xim2'   -- OPM�i�ڏ��View(�i��)
    || ',xxcmn_item_categories4_v    xic'   -- OPM�i�ڃJ�e�S������View
    || ',xxcmn_vendors2_v            xvv'   -- �d������View
    || ',xxcmn_vendor_sites2_v      xvsv'   -- �d����T�C�g���View
    || ',xxcmn_item_locations2_v    xilv'   -- OPM�ۊǏꏊ���View
    || ',xxpo_security_supply_v     xssv'   -- �L���x���Z�L�����e�BView
    ;
--
    -- ====================================================
    -- �v�g�d�q�d�吶��
    -- ====================================================
    lv_where := ' WHERE'
    -- �󒍃w�b�_�A�h�I���i��
    || '     xoha.latest_external_flag        = ''' || gc_yn_div_y          || ''''
    || ' AND xoha.req_status                 < '''  || gc_req_status_p_ccl  || ''''
    || ' AND xoha.req_status                 >= ''' || gc_req_status_s_cmpd || ''''
    || ' AND xoha.designated_production_date >=  '  || lv_date_from
     -- �󒍃^�C�v����
    || ' AND otta.org_id                   = '   || gn_prof_org_id
    || ' AND otta.attribute1               = ''' || gc_sp_class_prov || ''''
    || ' AND otta.order_category_code     <> ''' || gc_order_cat_r   || ''''
    || ' AND otta.attribute11              = ''' || gc_sp_category_s || ''''
    || ' AND xoha.order_type_id            = otta.transaction_type_id'
    -- �󒍖��׃A�h�I������
    || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
    || ' AND xoha.order_header_id          = xola.order_header_id'
    -- �ړ����b�g�ڍ׃A�h�I������
    || ' AND xmld.document_type_code       = ''' || gc_doc_type_prov || ''''
    || ' AND xmld.record_type_code         = ''' || gc_rec_type_inst || ''''
    || ' AND xola.order_line_id            = xmld.mov_line_id'
    -- OPM���b�g�}�X�^����
    || ' AND xmld.item_id                  = ilm.item_id'
    || ' AND xmld.lot_id                   = ilm.lot_id'
    -- OPM�i�ڏ��VIEW(�����i��)����
    || ' AND ' || lv_date_from || ' BETWEEN xim1.start_date_active'
    || '                            AND NVL(xim1.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    -- 2008/06/07 UPD START Y.Takayama
    --|| ' AND xoha.designated_item_id = xim1.item_id'
    || ' AND xoha.designated_item_id = xim1.inventory_item_id'
    -- 2008/06/07 UPD END   Y.Takayama
    -- OPM�i�ڏ��VIEW(�i��)����
    || ' AND ' || lv_date_from || ' BETWEEN xim2.start_date_active'
    || '                            AND NVL(xim2.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xola.shipping_inventory_item_id = xim2.inventory_item_id'
    -- OPM�i�ڃJ�e�S���������VIEW����
    || ' AND xim2.item_id                   = xic.item_id'
    -- �d������VIEW����
    || ' AND ' || lv_date_from || '  BETWEEN xvv.start_date_active'
    || '                             AND NVL(xvv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.vendor_id                = xvv.vendor_id'
    -- �d����T�C�g���VIEW����
    || ' AND ' || lv_date_from || '  BETWEEN xvsv.start_date_active'
    || '                             AND NVL(xvsv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.vendor_site_id                = xvsv.vendor_site_id'
    -- OPM�ۊǏꏊVIEW����
    || ' AND ' || lv_date_from || '  BETWEEN xilv.date_from'
    || '                             AND NVL(xilv.date_to'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.deliver_from_id = xilv.inventory_location_id'
    -- �L���x���Z�L�����e�BVIEW����
    || ' AND xssv.user_id                  = ''' || gn_user_id || ''''
    || ' AND xssv.security_class           = ''' || gr_param.security_div || ''''
    || ' AND xoha.vendor_code              = NVL(xssv.vendor_code,xoha.vendor_code)'
    || ' AND xoha.vendor_site_code         = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'
    ;
--
    -- ----------------------------------------------------
    -- �C�Ӄp�����[�^�ɂ�����
    -- ----------------------------------------------------
--
    -- �����
    IF (gr_param.vendor_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.vendor_code = ''' || gr_param.vendor_code || ''''
      ;
    END IF ;
--
    -- �z����
    IF (gr_param.deliver_to_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.vendor_site_code = ''' || gr_param.deliver_to_code || ''''
      ;
    END IF ;
--
    -- �����i��01
    IF (gr_param.design_item_code_01 IS NOT NULL) THEN
      lv_work_str := gr_param.design_item_code_01;
    END IF;
    -- �����i��02
    IF (gr_param.design_item_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.design_item_code_02 ;
    END IF;
    -- �����i��03
    IF (gr_param.design_item_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.design_item_code_03 ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xim1.item_no IN('||lv_work_str || ')';
      lv_work_str := NULL ;
    END IF ;
--
    -- �����ԍ�
    IF (gr_param.design_no IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.designated_branch_no = ''' || gr_param.design_no || ''''
      ;
    END IF ;
--
    -- ������TO
    IF (gr_param.date_to IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.designated_production_date'
      || '     <= FND_DATE.STRING_TO_DATE(''' || gr_param.date_to || '''' || ',''' || gc_date_mask || ''')'
      ;
    END IF ;
--
    -- ====================================================
    -- �n�q�c�d�q  �a�x�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY'
    || ' xoha.vendor_code'
    || ',xoha.vendor_site_code'
    || ',xim1.item_no'
    || ',xoha.designated_production_date'
    || ',xoha.designated_branch_no'
    || ',xic.item_class_code DESC'
    || ',xola.shipping_item_code'
    -- �i�ڋ敪�����i�̏ꍇ�́u�����N����+�ŗL�L���v����ȊO�u���b�gNo�v
    || ',DECODE(xic.item_class_code,''' || gc_item_div_prod || ''''
    || '       ,CONCAT(ilm.attribute1,ilm.attribute2),ilm.lot_no)'
    || ',xoha.deliver_from'
    ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    gv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
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
--##### �Œ��O������ END   #######################################################################
  END prc_create_sql ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(N-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O���� ***
    dtldata_notfound_expt      EXCEPTION ;     -- �Ώۃf�[�^0����O
    -- *** ���[�J���萔 ***
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
    -- *** ���[�J���ϐ� ***
    lt_data_rec        tab_data_type_dtl ;
    -- �u���C�N���f�p�ϐ�
    lv_vendor_code       VARCHAR2(4)  DEFAULT lc_init ;
    lv_deliver_to_code   VARCHAR2(4)  DEFAULT lc_init ;
    lv_design_item_code  VARCHAR2(7)  DEFAULT lc_init ;
    lv_design_date       VARCHAR2(10) DEFAULT lc_init ;
    lv_design_no         VARCHAR2(10) DEFAULT lc_init ;
--
  BEGIN
--
    EXECUTE IMMEDIATE gv_sql BULK COLLECT INTO lt_data_rec ;
    gn_data_cnt := lt_data_rec.count ;
--
    IF ( gn_data_cnt >= 1 ) THEN
      -- ==================================
      -- ��������
      -- ==================================
      -- ����惊�X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vendor_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      <<main_data_loop>>
      FOR i IN 1..lt_data_rec.count LOOP
        -- ====================================================
        -- �u���C�N����F�����O���[�v
        -- ====================================================
        IF ( lt_data_rec(i).vendor_code <> lv_vendor_code ) THEN
          IF ( lv_vendor_code <> lc_init ) THEN
            -- ----------------------------------------------------
            -- ���w�O���[�v�I���^�O�o��
            -- ----------------------------------------------------
            -- ���׃��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ��O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ����X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �������O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- ���������X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����i�ڃO���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����i�ڃ��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_item_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �z����O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_to';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �z���惊�X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver_to_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          -- �����O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �����R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).vendor_code;
          -- ����於
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).vendor_name;
          -- �z���惊�X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver_to_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
  --
          -- TMP�����F�Z�b�g
          lv_vendor_code       := lt_data_rec(i).vendor_code ;
          -- ���wG�F�u���C�N��������Z�b�g
          lv_deliver_to_code   := lc_init ;
          lv_design_item_code  := lc_init ;
          lv_design_date       := lc_init ;
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- �u���C�N����F�z����O���[�v
        -- ====================================================
        IF ( lt_data_rec(i).deliver_to_code <> lv_deliver_to_code ) THEN
          IF ( lv_deliver_to_code <> lc_init ) THEN
            -- ----------------------------------------------------
            -- ���w�O���[�v�I���^�O�o��
            -- ----------------------------------------------------
            -- ���׃��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ��O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ����X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �������O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- ���������X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����i�ڃO���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����i�ڃ��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_item_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �z����O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_to';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          -- �z����O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver_to';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �z����R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_to_code;
          -- �z���於
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_to_name;
          -- �����i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_design_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP�z����F�Z�b�g
          lv_deliver_to_code   := lt_data_rec(i).deliver_to_code ;
          -- ���wG�F�u���C�N��������Z�b�g
          lv_design_item_code  := lc_init ;
          lv_design_date       := lc_init ;
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- �u���C�N����F�����i�ڃO���[�v
        -- ====================================================
        IF ( lt_data_rec(i).design_item_code <> lv_design_item_code ) THEN
          IF ( lv_design_item_code <> lc_init ) THEN
            -- ----------------------------------------------------
            -- ���w�O���[�v�I���^�O�o��
            -- ----------------------------------------------------
            -- ���׃��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ��O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ����X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �������O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- ���������X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����i�ڃO���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          -- �����i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_design_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �����i�ڃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_item_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_item_code;
          -- �����i�ږ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_item_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_item_name;
          -- ���������X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_design_date_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP�����i�ځF�Z�b�g
          lv_design_item_code   := lt_data_rec(i).design_item_code ;
          -- ���wG�F�u���C�N��������Z�b�g
          lv_design_date       := lc_init ;
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- �u���C�N����F�������O���[�v
        -- ====================================================
        IF ( lt_data_rec(i).design_date <> lv_design_date ) THEN
          IF ( lv_design_date <> lc_init ) THEN
            -- ----------------------------------------------------
            -- ���w�O���[�v�I���^�O�o��
            -- ----------------------------------------------------
            -- ���׃��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ��O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ����X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �������O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          -- �������O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_design_date';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_date';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_date;
          -- ���������X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_design_no_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP�����i�ځF�Z�b�g
          lv_design_date   := lt_data_rec(i).design_date ;
          -- ���wG�F�u���C�N��������Z�b�g
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- �u���C�N����F�����ԍ��O���[�v
        -- ====================================================
    -- 2008/06/04 UPD START Y.Yamamoto
--        IF ( lt_data_rec(i).design_no <> lv_design_no ) THEN
        IF ( NVL(lt_data_rec(i).design_no,'@') <> lv_design_no ) THEN
          IF ( lv_design_no <> lc_init ) THEN
    -- 2008/06/04 UPD END Y.Yamamoto
            -- ----------------------------------------------------
            -- ���w�O���[�v�I���^�O�o��
            -- ----------------------------------------------------
            -- ���׃��X�g�O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �����ԍ��O���[�v
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          -- �����ԍ��O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_design_no';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �����ԍ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_no';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_no;
          -- �����ԍ����X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP�����i�ځF�Z�b�g
    -- 2008/06/04 UPD START Y.Yamamoto
--          lv_design_no   := lt_data_rec(i).design_no ;
          lv_design_no   := NVL(lt_data_rec(i).design_no,'@') ;
    -- 2008/06/04 UPD END Y.Yamamoto
--
        END IF ;
--
        -- ==================================
        -- ���׏o�́F���׃O���[�v
        -- ==================================
        -- ���׃O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_code;
        -- �i�ږ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_name;
        -- �t��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).futai_code;
        -- ���b�gNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).lot_no;
        -- ������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'maked_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).maked_date;
        -- �ܖ�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).limit_date;
        -- �ŗL�L��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'orgn_sign' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).orgn_sign;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).entry_quant;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).quant;
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'unit' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).unit;
        -- �o�ɑq�ɃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_code;
        -- �o�ɑq�ɖ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_name;
        -- ���דE�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_desc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dtl_desc;
        -- �˗�No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).request_no;
        -- ���ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrival_date;
        -- ���׃O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      END LOOP main_data_loop ;
--
      -- ==================================
      -- �I������
      -- ==================================
      -- ���׃��X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �����ԍ��O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �����ԍ����X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �������O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- ���������X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �����i�ڃO���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �����i�ڃ��X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_item_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �z����O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_to';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �z���惊�X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver_to_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- �����O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- ����惊�X�g�O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    END IF ;
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
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
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_vendor_code         IN   VARCHAR2  -- 01 : �����
     ,iv_deliver_to_code     IN   VARCHAR2  -- 02 : �z����
     ,iv_design_item_code_01 IN   VARCHAR2  -- 03 : �����i�ڂP
     ,iv_design_item_code_02 IN   VARCHAR2  -- 04 : �����i�ڂQ
     ,iv_design_item_code_03 IN   VARCHAR2  -- 05 : �����i�ڂR
     ,iv_date_from           IN   VARCHAR2  -- 06 : �o�ɓ�From
     ,iv_date_to             IN   VARCHAR2  -- 07 : �o�ɓ�To
     ,iv_design_no           IN   VARCHAR2  -- 08 : �����ԍ�
     ,iv_security_div        IN   VARCHAR2  -- 09 : �L���Z�L�����e�B�敪
     ,ov_errbuf              OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              VARCHAR2(1) ;
--
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
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
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.vendor_code         :=  iv_vendor_code;         -- 01 : �����
    gr_param.deliver_to_code     :=  iv_deliver_to_code;     -- 02 : �z����
    gr_param.design_item_code_01 :=  iv_design_item_code_01; -- 03 : �����i�ڂP
    gr_param.design_item_code_02 :=  iv_design_item_code_02; -- 04 : �����i�ڂQ
    gr_param.design_item_code_03 :=  iv_design_item_code_03; -- 05 : �����i�ڂR
-- UPDATE START 2008/5/20 YTabata --
    gr_param.date_from                                   -- 06 : �o�ɓ�From
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_from ),'YYYY/MM/DD');
    gr_param.date_to                                     -- 07 : �o�ɓ�To
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_to ),'YYYY/MM/DD');
/**
    gr_param.date_from           :=  iv_date_from;           -- 06 : �o�ɓ�From
    gr_param.date_to             :=  iv_date_to;             -- 07 : �o�ɓ�To
**/
-- UPDATE END 2008/5/20 YTabata --
    gr_param.design_no           :=  iv_design_no;           -- 08 : �����ԍ�
    gr_param.security_div        :=  iv_security_div;        -- 09 : �L���Z�L�����e�B�敪
--
    -- -----------------------------------------------------
    -- �c�ƒP�ʎ擾
    -- -----------------------------------------------------
    gn_prof_org_id := FND_PROFILE.VALUE( gc_prof_org_id ) ;
    IF ( gn_prof_org_id IS NULL ) THEN
      lv_err_code := gc_err_code_no_prof ;
      RAISE get_value_expt ;
    END IF ;
--
    -- =====================================================
    -- �f�[�^�擾�r�p�k����
    -- =====================================================
    prc_create_sql
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���O�C�����[�U�[���o��
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�l�k�t�@�C���f�[�^�ҏW
    -- =====================================================
    -- --------------------------------------------------
    -- ���X�g�O���[�v�J�n�^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- �w�l�k�f�[�^�ҏW�������Ăяo���B
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- ���X�g�O���[�v�I���^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- ���[�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_deliver_to_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_deliver_to>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <lg_design_item_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <g_design_item>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <lg_design_date_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    <g_design_date>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                      <lg_design_no_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                        <g_design_no>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                          <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                        </g_design_no>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                      </lg_design_no_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    </g_design_date>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  </lg_design_date_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </g_design_item>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </lg_design_item_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_deliver_to>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_deliver_to_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </data_info>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- �w�l�k�o��
      -- --------------------------------------------------
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
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
  PROCEDURE main
    (
      errbuf                 OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode                OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_vendor_code         IN     VARCHAR2         -- 01 : �����
     ,iv_deliver_to_code     IN     VARCHAR2         -- 02 : �z����
     ,iv_design_item_code_01 IN     VARCHAR2         -- 03 : �����i�ڂP
     ,iv_design_item_code_02 IN     VARCHAR2         -- 04 : �����i�ڂQ
     ,iv_design_item_code_03 IN     VARCHAR2         -- 05 : �����i�ڂR
     ,iv_date_from           IN     VARCHAR2         -- 06 : �o�ɓ�From
     ,iv_date_to             IN     VARCHAR2         -- 07 : �o�ɓ�To
     ,iv_design_no           IN     VARCHAR2         -- 08 : �����ԍ�
     ,iv_security_div        IN     VARCHAR2         -- 09 : �L���Z�L�����e�B�敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ;  -- �v���O������
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
        iv_vendor_code         -- 01 : �����
       ,iv_deliver_to_code     -- 02 : �z����
       ,iv_design_item_code_01 -- 03 : �����i�ڂP
       ,iv_design_item_code_02 -- 04 : �����i�ڂQ
       ,iv_design_item_code_03 -- 05 : �����i�ڂR
       ,iv_date_from           -- 06 : �o�ɓ�From
       ,iv_date_to             -- 07 : �o�ɓ�To
       ,iv_design_no           -- 08 : �����ԍ�
       ,iv_security_div        -- 09 : �L���Z�L�����e�B�敪
       ,lv_errbuf              -- �G���[�E���b�Z�[�W
       ,lv_retcode             -- ���^�[���E�R�[�h
       ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
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
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo440006c ;
/
