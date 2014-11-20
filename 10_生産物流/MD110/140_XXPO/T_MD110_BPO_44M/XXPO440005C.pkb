CREATE OR REPLACE PACKAGE BODY xxpo440005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440005(body)
 * Description      : �L�����ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44M)
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[��� (M-1)
 *  prc_create_sql              PROCEDURE : �f�[�^�擾�r�p�k���� (M-2)
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW (M-3)
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/19    1.0   Yusuke Tabata   �V�K�쐬
 *  2008/05/20    1.1   Yusuke Tabata   �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/06/03    1.2   Yohei  Takayama �����e�X�g�s�#440_46�Ή�
 *  2008/06/04    1.3 Yasuhisa Yamamoto �����e�X�g�s����O#440_54
 *  2008/06/19    1.4   Kazuo Kumamoto  �����e�X�g���r���[�w�E����#18�Ή�
 *  2008/07/02    1.5   Satoshi Yunba   �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
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
--  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440005C' ;      -- �p�b�P�[�W��
--  gc_report_id            CONSTANT VARCHAR2(20) := 'xxpo440005T' ;      -- ���[ID
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXPO440005C' ;      -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440005T' ;      -- ���[ID
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
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER'  ; -- ��
  -- �󒍃J�e�S���F�o�׎x���敪
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- �x���˗�
  -- �󒍃J�e�S���F�o�׎x���󕥃J�e�S��
  gc_sp_category_s        CONSTANT VARCHAR2(2)  := '05' ;   -- �L���o��
--add start 1.4
  gc_sp_category_r        CONSTANT VARCHAR2(2)  := '06' ;   -- �L���ԕi
--add end 1.4
  -- �󒍃w�b�_�A�h�I���F�ŐV�t���O�iYesNo�敪�j
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- �󒍃w�b�_�A�h�I���F�X�e�[�^�X
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99';    -- ���
  -- �󒍃w�b�_�A�h�I���F�L�����z�m��敪
  gc_amount_fix_cmpc      CONSTANT VARCHAR2(1)  := '1' ;    -- �m���
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- �x���w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_stck        CONSTANT VARCHAR2(2)  := '20';    -- �o�Ɏ���
  -- �n�o�l�i�ڃ}�X�^�F���b�g�Ǘ��敪
  gc_lot_ctl_y            CONSTANT NUMBER(1)    := 1 ;      -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT NUMBER(1)    := 0 ;      -- ���b�g�Ǘ��Ȃ�
  -- �n�o�l�i�ڃJ�e�S���F�i�ڋ敪
  gc_item_div_prod        CONSTANT VARCHAR2(1)  := '5' ;    -- ���i
  ------------------------------
  -- ���̑�
  ------------------------------
  -- �ԕi��������
  gc_rtn_sign_y     CONSTANT VARCHAR2(1)  := '1' ;   -- �ԕior�ԕi����
  gc_rtn_sign_n     CONSTANT VARCHAR2(1)  := '0' ;   -- �ԕior�ԕi�����O
  -- �ő���t
  gc_max_date_char  CONSTANT VARCHAR2(10) := '4712/12/31' ;
  -- ���t�}�X�N
  gc_date_mask      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b�}�X�N
  gc_date_mask_m    CONSTANT VARCHAR2(8)  := 'YY/MM/DD' ;              -- �N����(YY/MM/DD)�}�X�N
  gc_date_mask_s    CONSTANT VARCHAR2(21) := 'MM/DD' ;                 -- �����}�X�N
  gc_date_mask_ja   CONSTANT VARCHAR2(19) := 'YYYY"�N"MM"��"DD"��' ;   -- �N����(JA)�}�X�N
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
      date_from          VARCHAR2(10) -- 01 : �o�ɓ�From
     ,date_to            VARCHAR2(10) -- 02 : �o�ɓ�To
     ,prod_div           VARCHAR2(1)  -- 03 : ���i�敪
     ,dept_code          VARCHAR2(4)  -- 04 : �S������
     ,vendor_code_01     VARCHAR2(4)  -- 05 : �����P
     ,vendor_code_02     VARCHAR2(4)  -- 06 : �����Q
     ,vendor_code_03     VARCHAR2(4)  -- 07 : �����R
     ,vendor_code_04     VARCHAR2(4)  -- 08 : �����S
     ,vendor_code_05     VARCHAR2(4)  -- 09 : �����T
     ,item_div           VARCHAR2(1)  -- 10 : �i�ڋ敪
     ,crowd_code_01      VARCHAR2(4)  -- 11 : �Q�P
     ,crowd_code_02      VARCHAR2(4)  -- 12 : �Q�Q
     ,crowd_code_03      VARCHAR2(4)  -- 13 : �Q�R
     ,item_code_01       VARCHAR2(7)  -- 14 : �i�ڂP
     ,item_code_02       VARCHAR2(7)  -- 15 : �i�ڂQ
     ,item_code_03       VARCHAR2(7)  -- 16 : �i�ڂR
     ,security_div       VARCHAR2(1)  -- 17 : �L���Z�L�����e�B�敪
    ) ;
--
  -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl IS RECORD
    (
       prod_div_type     xxcmn_item_categories4_v.prod_class_code%TYPE      -- ���i�敪�i���i�敪�R�[�h�j
      ,prod_div_name     xxcmn_item_categories4_v.prod_class_name%TYPE      -- ���i�敪�i���i�敪���j
      ,dept_code         xxcmn_locations2_v.location_code%TYPE              -- �S�������i�����R�[�h�j
      ,dept_name         xxcmn_locations2_v.location_name%TYPE              -- �S�������i�������j
      ,vendor_code       xxcmn_vendors2_v.segment1%TYPE                     -- �z����i�z����R�[�h�j
      ,vendor_name       xxcmn_vendors2_v.vendor_short_name%TYPE            -- �z����i�z���於�j
      ,item_div_type     xxcmn_item_categories4_v.item_class_code%TYPE      -- �i�ڋ敪(�i�ڋ敪�R�[�h)
      ,item_div_name     xxcmn_item_categories4_v.item_class_name%TYPE      -- �i�ڋ敪�i�i�ڋ敪��
      ,crowd_code        xxcmn_item_categories4_v.crowd_code%TYPE           -- �Q�i�Q�R�[�h�j
      ,item_code         xxcmn_item_mst2_v.item_no%TYPE                     -- �i�ځi�i�ڃR�[�h�j
      -- 2008/06/03 UPD START Y.Takayama
      --,item_name         xxcmn_item_mst2_v.item_desc1%TYPE                  -- �i�ځi�i�ږ��j
      ,item_name         xxcmn_item_mst2_v.item_short_name%TYPE             -- �i�ځi�i�ږ��j
      -- 2008/06/03 UPD END   Y.Takayama
      ,futai_code        xxwsh_order_lines_all.futai_code%TYPE              -- �t��
      ,shipped_date      VARCHAR2(5)                                        -- �o�ɓ�(MM/DD)
      ,lot_no            ic_lots_mst.lot_no%TYPE                            -- ���b�gNo
      ,maked_date        ic_lots_mst.attribute1%TYPE                        -- ������
      ,limit_date        ic_lots_mst.attribute3%TYPE                        -- �ܖ�����
      ,orgn_sign         ic_lots_mst.attribute2%TYPE                        -- �ŗL�L��
      ,arrival_date      VARCHAR2(5)                                        -- ���ɓ�(MM/DD)
      ,request_no        xxwsh_order_headers_all.request_no%TYPE            -- �˗�No
      ,entry_quant       xxcmn_item_mst2_v.frequent_qty%TYPE                -- ����
      ,quant             xxinv_mov_lot_details.actual_quantity%TYPE         -- ����
      ,unit              xxwsh_order_lines_all.uom_code%TYPE                -- �P��
      ,unt_price         xxwsh_order_lines_all.unit_price%TYPE              -- �P��
      ,price             NUMBER                                             -- ���z
      ,rtn_sign          VARCHAR2(1)                                        -- �ԕi����
      ,deliver_to        xxcmn_vendor_sites2_v.vendor_site_code%TYPE        -- �z����
      ,dtl_desc          xxwsh_order_lines_all.line_description%TYPE        -- ���דE�v
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
   * Description      : ���[�U�[���^�O�o��(M-1)
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
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- ���[�U�[�f�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �p�����[�^�f�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- �o�ɓ�FORM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_from' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(gr_param.date_from),gc_date_mask_ja) ;
    -- �o�ɓ�TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_to' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(gr_param.date_to),gc_date_mask_ja) ;
--
    -- ====================================================
    -- �p�����[�^�f�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
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
   * Procedure Name   : prc_create_sql(M-2)
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
    || ' xic.prod_class_code           AS prod_div_type' -- ���i�敪�i���i�敪�R�[�h�j
    || ',xic.prod_class_name           AS prod_div_name' -- ���i�敪�i���i�敪���j
    || ',xlv.location_code             AS dept_code'     -- �S�������i�����R�[�h�j
    || ',xlv.location_name             AS dept_name'     -- �S�������i�������j
    || ',xvv.segment1                  AS vendor_code'   -- �����i�����R�[�h�j
    || ',xvv.vendor_short_name         AS vendor_name'   -- �����i����於�j
    || ',xic.item_class_code           AS item_div_type' -- �i�ڋ敪(�i�ڋ敪�R�[�h)
    || ',xic.item_class_name           AS item_div_name' -- �i�ڋ敪�i�i�ڋ敪��)
    || ',xic.crowd_code                AS crowd_code'    -- �Q�i�Q�R�[�h�j
    || ',xim.item_no                   AS item_code'     -- �i�ځi�i�ڃR�[�h�j
    -- 2008/06/03 UPD START Y.Takayama
    --|| ',xim.item_desc1                AS item_name'     -- �i�ځi�i�ږ��j
    || ',xim.item_short_name           AS item_name'     -- �i�ځi�i�ږ��j
    -- 2008/06/03 UPD END   Y.Takayama
    || ',xola.futai_code               AS futai_code'    -- �t��
    || ',TO_CHAR(xoha.shipped_date,'
    || '''' || gc_date_mask_s || ''' ) AS shipped_date'  -- �o�ɓ�(MN/DD)
    -- ���b�g���o��:���b�g�Ǘ��i����
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.lot_no'
    || '   ELSE '
    || '     NULL'
    || ' END                           AS lot_no'        -- ���b�gNo
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute1)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS maked_date'    -- ������
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute3)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS limit_date'    -- �ܖ�����
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute2'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS orgn_sign'     -- �ŗL�L��
    || ',TO_CHAR(xoha.arrival_date,'
    || '''' || gc_date_mask_s || ''' ) AS arrival_date'  -- ���ɓ�(MM/DD)
    || ',xoha.request_no               AS request_no'    -- �˗�No
    -- �����o��:���b�g�Ǘ��i����
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute6'
    || '   ELSE'
    || '     xim.frequent_qty'
    || ' END                           AS entry_quant'   -- ����
    -- �����o��:�ԕi����
    || ',CASE'
    || '   WHEN otta.order_category_code = ''' || gc_order_cat_r || ''' THEN'
    || '     (xmld.actual_quantity * -1)'
    || '   ELSE'
    || '     xmld.actual_quantity'
    || '   END                         AS quant'         -- ����
    || ',xola.uom_code                 AS unit'          -- �P��
    || ',xola.unit_price               AS unt_price'     -- �P��
    || ',CASE'
    || '   WHEN otta.order_category_code = ''' || gc_order_cat_r || ''' THEN'
    || '     ROUND(xmld.actual_quantity * xola.unit_price * -1)'
    || '   ELSE'
    || '     ROUND(xmld.actual_quantity * xola.unit_price)'
    || ' END                          AS price'         -- ���z
    -- �ԕi��������t���O
    || ',CASE'
--mod start 1.4
--    || '   WHEN otta.attribute11 = ''' || gc_order_cat_o || '''' || ' THEN'
    || '   WHEN otta.attribute11 = ''' || gc_sp_category_r || '''' || ' THEN'
--mod end 1.4
    || '     '''  || gc_rtn_sign_y || ''''
    || '   ELSE'
    || '     '''  || gc_rtn_sign_n || ''''
    || ' END                           AS rtn_sign'     -- �ԕi����
    || ',xoha.vendor_site_code         AS deliver_to'   -- �z����
    || ',xola.line_description         AS dtl_desc'     -- ���דE�v
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
    || ',ic_lots_mst                ilm'    -- OPM���b�g�}�X�^
    || ',xxcmn_item_mst2_v          xim'    -- OPM�i�ڏ��View
    || ',xxcmn_item_categories4_v   xic'    -- OPM�i�ڃJ�e�S������View
    || ',xxcmn_vendors2_v           xvv'    -- �d������View
    || ',xxcmn_locations2_v         xlv'    -- ���Ə����View
    || ',xxpo_security_supply_v    xssv'    -- �L���x���Z�L�����e�BView
    ;
--
    -- ====================================================
    -- �v�g�d�q�d�吶��
    -- ====================================================
    lv_where := ' WHERE'
    -- �󒍃w�b�_�A�h�I���i��
    || '     xoha.latest_external_flag     = ''' || gc_yn_div_y         || ''''
    || ' AND xoha.amount_fix_class         = ''' || gc_amount_fix_cmpc  || ''''
    || ' AND xoha.req_status              <> ''' || gc_req_status_p_ccl || ''''
    || ' AND xoha.shipped_date            >=  '  || lv_date_from
     -- �󒍃^�C�v����
    || ' AND otta.org_id                   = '   || gn_prof_org_id
    || ' AND otta.attribute1               = ''' || gc_sp_class_prov || ''''
    || ' AND xoha.order_type_id            = otta.transaction_type_id'
    -- �󒍖��׃A�h�I������
    || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
    || ' AND xoha.order_header_id          = xola.order_header_id'
    -- �ړ����b�g�ڍ׃A�h�I������
    || ' AND xmld.document_type_code       = ''' || gc_doc_type_prov || ''''
    || ' AND xmld.record_type_code         = ''' || gc_rec_type_stck || ''''
    || ' AND xola.order_line_id            = xmld.mov_line_id'
    -- OPM���b�g�}�X�^����
    || ' AND xmld.item_id                  = ilm.item_id'
    || ' AND xmld.lot_id                   = ilm.lot_id'
    -- OPM�i�ڏ��VIEW����
    || ' AND ' || lv_date_from || ' BETWEEN xim.start_date_active'
    || '                            AND NVL(xim.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xola.shipping_inventory_item_id = xim.inventory_item_id'
    -- OPM�i�ڃJ�e�S���������VIEW����
    || ' AND xim.item_id                   = xic.item_id'
    -- �d������VIEW����
    || ' AND ' || lv_date_from || '  BETWEEN xvv.start_date_active'
    || '                             AND NVL(xvv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.vendor_id                = xvv.vendor_id'
    -- ���Ə����VIEW����
    || ' AND ' || lv_date_from || '  BETWEEN xlv.start_date_active'
    || '                             AND NVL(xlv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.performance_management_dept = xlv.location_code'
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
    -- ���i�敪
    IF (gr_param.prod_div IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xic.prod_class_code = ''' || gr_param.prod_div || ''''
      ;
    END IF ;
--
    -- �S������
    IF (gr_param.dept_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.performance_management_dept = ''' || gr_param.dept_code || ''''
      ;
    END IF ;
--
    -- �����01
    IF (gr_param.vendor_code_01 IS NOT NULL) THEN
      lv_work_str := gr_param.vendor_code_01;
    END IF;
    -- �����02
    IF (gr_param.vendor_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_02 ;
    END IF;
    -- �����03
    IF (gr_param.vendor_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_03 ;
    END IF;
    -- �����04
    IF (gr_param.vendor_code_04 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_04 ;
    END IF ;
    -- �����05
    IF (gr_param.vendor_code_05 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_05 ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.vendor_code IN('||lv_work_str || ')';
      lv_work_str := NULL ;
    END IF ;
--
    -- �i�ڋ敪
    IF (gr_param.item_div IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xic.item_class_code = ''' || gr_param.item_div || ''''
      ;
    END IF ;
--
    -- �Q01
    IF (gr_param.crowd_code_01 IS NOT NULL) THEN
      lv_work_str := lv_work_str
      || 'AND ((xic.crowd_code like '''|| gr_param.crowd_code_01 || '%'')'
      ;
    END IF;
    -- �Q02
    IF (gr_param.crowd_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ' OR' ;
      ELSE
        lv_work_str := lv_work_str || ' AND(' ;
      END IF;
      lv_work_str := lv_work_str
      || '  (xic.crowd_code like '''|| gr_param.crowd_code_02 || '%'')';
    END IF;
    -- �Q03
    IF (gr_param.crowd_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ' OR' ;
      ELSE
        lv_work_str := lv_work_str || ' AND(' ;
      END IF;
      lv_work_str := lv_work_str
      || '  (xic.crowd_code like '''|| gr_param.crowd_code_03 || '%'')';
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || lv_work_str  || ')' ;
      lv_work_str := NULL;
    END IF;
--
    -- �i��01
    IF (gr_param.item_code_01 IS NOT NULL) THEN
      lv_work_str := gr_param.item_code_01;
    END IF;
    -- �i��02
    IF (gr_param.item_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.item_code_02 ;
    END IF;
    -- �i��03
    IF (gr_param.item_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.item_code_03 ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xim.item_no IN('||lv_work_str || ')';
      lv_work_str := NULL ;
    END IF ;
--
    -- �o�ɓ�TO
    IF (gr_param.date_to IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.shipped_date'
      || '     <= FND_DATE.STRING_TO_DATE(''' || gr_param.date_to || '''' || ',''' || gc_date_mask || ''')'
      ;
    END IF ;
--
    -- ====================================================
    -- �n�q�c�d�q  �a�x�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY'
    || ' xic.prod_class_code'
    || ',xoha.performance_management_dept'
    || ',xoha.vendor_code'
    || ',xic.item_class_code'
    || ',xic.crowd_code'
    || ',xola.shipping_item_code'
    || ',xola.futai_code'
    || ',xoha.shipped_date'
    -- �i�ڋ敪�����i�̏ꍇ�́u�����N����+�ŗL�L���v����ȊO�u���b�gNo�v
    || ',DECODE(xic.item_class_code,''' || gc_item_div_prod || ''''
    || '       ,CONCAT(ilm.attribute1,ilm.attribute2),ilm.lot_no)'
    || ',xoha.request_no'
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
   * Description      : �w�l�k�f�[�^�쐬(M-3)
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
    lv_prod_div_type     VARCHAR2(1)  DEFAULT lc_init ;
    ln_prod_div_count    NUMBER       DEFAULT 0;
    lv_dept_code         VARCHAR2(4)  DEFAULT lc_init ;
    ln_dept_code_count   NUMBER       DEFAULT 0;
    lv_vendor_code       VARCHAR2(4)  DEFAULT lc_init ;
    ln_vendor_code_count NUMBER       DEFAULT 0;
    lv_item_div_type     VARCHAR2(1)  DEFAULT lc_init ;
    ln_item_div_count    NUMBER       DEFAULT 0;
    lv_crowd_code        VARCHAR2(4)  DEFAULT lc_init ;
    lv_item_code         VARCHAR2(7)  DEFAULT lc_init ;
--
  BEGIN
--
    EXECUTE IMMEDIATE gv_sql BULK COLLECT INTO lt_data_rec ;
    gn_data_cnt := lt_data_rec.count ;
--
    -- ==================================
    -- ��������
    -- ==================================
    -- ���i�敪���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;	
--
    <<main_data_loop>>
    FOR i IN 1..lt_data_rec.count LOOP
      -- ====================================================
      -- �u���C�N����F���i�敪�O���[�v
      -- ====================================================
      IF ( lt_data_rec(i).prod_div_type <> lv_prod_div_type ) THEN
        IF ( lv_prod_div_type <> lc_init ) THEN
          -- ----------------------------------------------------
          -- ���w�O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
          -- �����O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ����惊�X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_dept_code_count;
          -- �S�������O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �S���������X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_prod_div_count;
          -- ���i�敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        -- ���i�敪�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- ���i�敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type;
        -- ���i�敪��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_name;
        -- �S���������X�g�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dept_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP���i�敪�F�Z�b�g
        lv_prod_div_type     := lt_data_rec(i).prod_div_type ;
        -- ���wG�F�u���C�N��������Z�b�g
        lv_dept_code         := lc_init ;
        lv_vendor_code       := lc_init ;
        lv_item_div_type     := lc_init ;
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- ���i�敪�J�E���g�F�C���N�������g
        ln_prod_div_count    := ln_prod_div_count + 1 ;
        -- ���wG���J�E���g �F������
        ln_dept_code_count   := 0 ;
        ln_vendor_code_count := 0 ;
        ln_item_div_count    := 0 ;
      END IF;
--
      -- ====================================================
      -- �u���C�N����F�S�������O���[�v
      -- ====================================================
      IF ( lt_data_rec(i).dept_code <> lv_dept_code ) THEN
        IF ( lv_dept_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- ���w�O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
          -- �����O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ����惊�X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_dept_code_count;
          -- �S�������O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        -- �S�������O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- �S�������R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dept_code;
        -- �S��������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dept_name;
        -- ����惊�X�g�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vendor_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP�S�������F�Z�b�g
        lv_dept_code         := lt_data_rec(i).dept_code ;
        -- ���wG�F�u���C�N��������Z�b�g
        lv_vendor_code       := lc_init ;
        lv_item_div_type     := lc_init ;
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- �S�������J�E���g�F�C���N�������g
        ln_dept_code_count   := ln_dept_code_count + 1 ;
        -- ���wG���J�E���g �F������
        ln_vendor_code_count := 0 ;
        ln_item_div_count    := 0 ;
      END IF ;
--
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
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
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
        -- �i�ڋ敪���X�g�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP�����F�Z�b�g
        lv_vendor_code       := lt_data_rec(i).vendor_code ;
        -- ���wG�F�u���C�N��������Z�b�g
        lv_item_div_type     := lc_init ;
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- �����J�E���g�F�C���N�������g
        ln_vendor_code_count := ln_vendor_code_count + 1 ;
        -- ���wG���J�E���g �F������
        ln_item_div_count    := 0 ;
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�i�ڋ敪�O���[�v
      -- ====================================================
      IF ( lt_data_rec(i).item_div_type <> lv_item_div_type ) THEN
        IF ( lv_item_div_type <> lc_init ) THEN
          -- ----------------------------------------------------
          -- ���w�O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �m�[�h�|�W�V����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        -- �i�ڋ敪�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- �i�ڋ敪�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
        -- �i�ڋ敪��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_name;
        -- �Q���X�g�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_crowd_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP�i�ڋ敪�F�Z�b�g
        lv_item_div_type     := lt_data_rec(i).item_div_type ;
        -- ���wG�F�u���C�N��������Z�b�g
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- �i�ڋ敪�J�E���g�F�C���N�������g
        ln_item_div_count := ln_item_div_count + 1 ;
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�Q�O���[�v
      -- ====================================================
      IF ( lt_data_rec(i).crowd_code <> lv_crowd_code ) THEN
        IF ( lv_crowd_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- ���w�O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �Q�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        -- �Q�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_crowd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- �Q�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'crowd_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).crowd_code;
        -- �i�ڃ��X�g�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP�Q�F�Z�b�g
        lv_crowd_code     := lt_data_rec(i).crowd_code ;
        -- ���wG�F�u���C�N��������Z�b�g
        lv_item_code         := lc_init ;
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�i�ڃO���[�v
      -- ====================================================
      IF ( lt_data_rec(i).item_code <> lv_item_code ) THEN
        IF ( lv_item_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- ���w�O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        -- �i�ڃO���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_code;
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_name;
        -- �i�ڃ��X�g�O���[�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP�i�ځF�Z�b�g
        lv_item_code     := lt_data_rec(i).item_code ;
      END IF ;
--
      -- ====================================================
      -- ���׏o�́F���׃O���[�v
      -- ====================================================
      -- ���׃O���[�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
		-- �t��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).futai_code;
      -- �o�ɓ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date;
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
      -- ���ɓ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrival_date;
      -- �˗�No
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).request_no;
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
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unt_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).unt_price;
      -- ���z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).price;
      -- �ԕi����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_sign' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- �ԕi����  �L(1)�F�u*�v��(0)�F�u�v
      IF (lt_data_rec(i).rtn_sign = gc_rtn_sign_y ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := '*' ;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
      END IF ;
		-- �z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_to;
      -- ���דE�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_desc' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dtl_desc;
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
    -- �i�ڃO���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �i�ڃ��X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �Q�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �Q���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �m�[�h�|�W�V����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
    -- �i�ڋ敪�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �i�ڋ敪���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �m�[�h�|�W�V����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
    -- �����O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ����惊�X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �m�[�h�|�W�V����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_dept_code_count;
    -- �S�������O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �S���������X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �m�[�h�|�W�V����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_prod_div_count;
    -- ���i�敪�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���i�敪���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
      iv_date_from           IN   VARCHAR2  -- 01 : �o�ɓ�From
     ,iv_date_to             IN   VARCHAR2  -- 02 : �o�ɓ�To
     ,iv_prod_div            IN   VARCHAR2  -- 03 : ���i�敪
     ,iv_dept_code           IN   VARCHAR2  -- 04 : �S������
     ,iv_vendor_code_01      IN   VARCHAR2  -- 05 : �����P
     ,iv_vendor_code_02      IN   VARCHAR2  -- 06 : �����Q
     ,iv_vendor_code_03      IN   VARCHAR2  -- 07 : �����R
     ,iv_vendor_code_04      IN   VARCHAR2  -- 08 : �����S
     ,iv_vendor_code_05      IN   VARCHAR2  -- 09 : �����T
     ,iv_item_div            IN   VARCHAR2  -- 10 : �i�ڋ敪
     ,iv_crowd_code_01       IN   VARCHAR2  -- 11 : �Q�P
     ,iv_crowd_code_02       IN   VARCHAR2  -- 12 : �Q�Q
     ,iv_crowd_code_03       IN   VARCHAR2  -- 13 : �Q�R
     ,iv_item_code_01        IN   VARCHAR2  -- 14 : �i�ڂP
     ,iv_item_code_02        IN   VARCHAR2  -- 15 : �i�ڂQ
     ,iv_item_code_03        IN   VARCHAR2  -- 16 : �i�ڂR
     ,iv_security_div        IN   VARCHAR2  -- 17 : �L���Z�L�����e�B�敪
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
-- UPDATE START 2008/5/20 YTabata --
    gr_param.date_from                                   -- 01 : �o�ɓ�From
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_from ),'YYYY/MM/DD');
    gr_param.date_to                                     -- 02 : �o�ɓ�To
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_to ),'YYYY/MM/DD');
/**
    gr_param.date_from       :=  iv_date_from ;          -- 01 : �o�ɓ�From
    gr_param.date_to         :=  iv_date_to ;            -- 02 : �o�ɓ�To
**/
-- UPDATE END 2008/5/20 YTabata --
    gr_param.prod_div        :=  iv_prod_div ;           -- 03 : ���i�敪
    gr_param.dept_code       :=  iv_dept_code ;          -- 04 : �S������
    gr_param.vendor_code_01  :=  iv_vendor_code_01 ;     -- 05 : �����P
    gr_param.vendor_code_02  :=  iv_vendor_code_02 ;     -- 06 : �����Q
    gr_param.vendor_code_03  :=  iv_vendor_code_03 ;     -- 07 : �����R
    gr_param.vendor_code_04  :=  iv_vendor_code_04 ;     -- 08 : �����S
    gr_param.vendor_code_05  :=  iv_vendor_code_05 ;     -- 09 : �����T
    gr_param.item_div        :=  iv_item_div ;           -- 10 : �i�ڋ敪
    gr_param.crowd_code_01   :=  iv_crowd_code_01 ;      -- 11 : �Q�P
    gr_param.crowd_code_02   :=  iv_crowd_code_02 ;      -- 12 : �Q�Q
    gr_param.crowd_code_03   :=  iv_crowd_code_03 ;      -- 13 : �Q�R
    gr_param.item_code_01    :=  iv_item_code_01 ;       -- 14 : �i�ڂP
    gr_param.item_code_02    :=  iv_item_code_02 ;       -- 15 : �i�ڂQ
    gr_param.item_code_03    :=  iv_item_code_03 ;       -- 16 : �i�ڂR
    gr_param.security_div    :=  iv_security_div ;       -- 17 : �L���Z�L�����e�B�敪
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_dept_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_dept>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_dept>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_dept_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_date_from          IN     VARCHAR2         -- 01 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 02 : �o�ɓ�To
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_dept_code          IN     VARCHAR2         -- 04 : �S������
     ,iv_vendor_code_01     IN     VARCHAR2         -- 05 : �����P
     ,iv_vendor_code_02     IN     VARCHAR2         -- 06 : �����Q
     ,iv_vendor_code_03     IN     VARCHAR2         -- 07 : �����R
     ,iv_vendor_code_04     IN     VARCHAR2         -- 08 : �����S
     ,iv_vendor_code_05     IN     VARCHAR2         -- 09 : �����T
     ,iv_item_div           IN     VARCHAR2         -- 10 : �i�ڋ敪
     ,iv_crowd_code_01      IN     VARCHAR2         -- 11 : �Q�P
     ,iv_crowd_code_02      IN     VARCHAR2         -- 12 : �Q�Q
     ,iv_crowd_code_03      IN     VARCHAR2         -- 13 : �Q�R
     ,iv_item_code_01       IN     VARCHAR2         -- 14 : �i�ڂP
     ,iv_item_code_02       IN     VARCHAR2         -- 15 : �i�ڂQ
     ,iv_item_code_03       IN     VARCHAR2         -- 16 : �i�ڂR
     ,iv_security_div       IN     VARCHAR2         -- 17 : �L���Z�L�����e�B�敪
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
        iv_date_from           -- 01 : �o�ɓ�From
       ,iv_date_to             -- 02 : �o�ɓ�To
       ,iv_prod_div            -- 03 : ���i�敪
       ,iv_dept_code           -- 04 : �S������
       ,iv_vendor_code_01      -- 05 : �����P
       ,iv_vendor_code_02      -- 06 : �����Q
       ,iv_vendor_code_03      -- 07 : �����R
       ,iv_vendor_code_04      -- 08 : �����S
       ,iv_vendor_code_05      -- 09 : �����T
       ,iv_item_div            -- 10 : �i�ڋ敪
       ,iv_crowd_code_01       -- 11 : �Q�P
       ,iv_crowd_code_02       -- 12 : �Q�Q
       ,iv_crowd_code_03       -- 13 : �Q�R
       ,iv_item_code_01        -- 14 : �i�ڂP
       ,iv_item_code_02        -- 15 : �i�ڂQ
       ,iv_item_code_03        -- 16 : �i�ڂR
       ,iv_security_div        -- 17 : �L���Z�L�����e�B�敪
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
END xxpo440005c ;
/
