CREATE OR REPLACE PACKAGE BODY xxcmn770008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770008c(body)
 * Description      : �ԕi�����������ٕ\
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77H)
 * Version          : 1.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(H-1)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(H-2)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0   T.Ikehara        �V�K�쐬
 *  2008/05/15    1.1   T.Ikehara        �����N���p��YYYYM���͑Ή�
 *                                       �S�������A�S���Җ��̍ő咷�������C��
 *  2008/06/03    1.2   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/10    1.3   T.Ikehara        �����i�Ɛ��i�̃��C���^�C�v���C��
 *  2008/06/13    1.4   T.Ikehara        ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜
 *  2008/06/19    1.5   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/26    1.7   A.Shiina         T_TE080_BPO_770 �w�E17�Ή�
 *  2008/10/15    1.8   N.Yoshida        T_S_524�Ή�(PT�Ή�)
 *  2008/11/11    1.9   N.Yoshida        �ڍs�f�[�^���؎��s��Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal          CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn            CONSTANT VARCHAR2(1)  := '1';
  gv_status_error           CONSTANT VARCHAR2(1)  := '2';
  gv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
  gv_haifn                  CONSTANT VARCHAR2(1)  := '-';
  gv_ja                     CONSTANT VARCHAR2(2)  := 'JA';
  gn_po_qty                 CONSTANT NUMBER  := 1;
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
  -- ���[�U�[��`��O
  -- ===============================
  global_user_expt          EXCEPTION;     -- ���[�U�[�ɂĒ�`��������O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn770008C';   -- �p�b�P�[�W��
  gv_print_name           CONSTANT VARCHAR2(20) := '�ԕi�����������ٕ\' ;   -- ���[��
--
  ------------------------------
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN'; -- �A�v���P�[�V����
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_ym_format       CONSTANT VARCHAR2(30) := 'YYYYMM';
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  gc_char_ym_jp_format    CONSTANT VARCHAR2(30) := 'YYYY"�N"MM"��"';
  gc_d                    CONSTANT VARCHAR2(1) := 'D';
  gc_n                    CONSTANT VARCHAR2(1) := 'N';
  gc_t                    CONSTANT VARCHAR2(1) := 'T';
  gc_z                    CONSTANT VARCHAR2(1) := 'Z';
  gn_one                  CONSTANT NUMBER      := 1  ;
  gc_sla                  CONSTANT VARCHAR2(1) := '/' ;
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(10)                          -- 01 : �����N���i�K�{)
     ,goods_class         VARCHAR2(10)                          -- 02 : ���i�敪�i�K�{)
     ,item_class          VARCHAR2(10)                          -- 03 : �i�ڋ敪�i�K�{)
     ,rcv_pay_div         VARCHAR2(10)                          -- 04 : �󕥋敪�i�C��)
    );
--
  -- �󕥎c���\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      item_code          xxcmn_lot_each_item_v.item_code%TYPE              -- �ԕi�����i�ڃR�[�h
     ,item_name          xxcmn_lot_each_item_v.item_short_name%TYPE        -- �ԕi�����i�ږ���
     ,product_item_code  xxcmn_lot_each_item_v.item_code%TYPE              -- ���i�i�ڃR�[�h
     ,product_item_name  xxcmn_lot_each_item_v.item_short_name%TYPE        -- ���i�i�ږ���
     ,quantity           ic_tran_pnd.trans_qty%TYPE                        -- �������(����)
-- 2008/11/11 v1.9 UPDATE START
     --,standard_cost      xxcmn_stnd_unit_price_v.stnd_unit_price_gen%TYPE  -- �W������(����)
     ,standard_cost      xxcmn_stnd_unit_price_v.stnd_unit_price%TYPE  -- �W������(����)
-- 2008/11/11 v1.9 UPDATE END
     ,turn_qty           ic_tran_pnd.trans_qty%TYPE                        -- �����(���i)
     ,turn_price         NUMBER                                            -- ��P��(���i)
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ���i�E�����̕������݃`�F�b�N�p
  TYPE rec_double_check IS RECORD(
      batch_no           gme_batch_header.batch_no%TYPE  -- �o�b�`�m��
     ,cnt                NUMBER                          -- �����J�E���g
    );
  TYPE tab_double_check IS TABLE OF rec_double_check INDEX BY BINARY_INTEGER ;
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  gd_exec_start             DATE;             -- �����N���̊J�n��
  gd_exec_end               DATE;             -- �����N���̏I����
  gv_exec_start             VARCHAR2(20);     -- �����N���̊J�n��
  gv_exec_end               VARCHAR2(20);     -- �����N���̏I����
  ------------------------------
  -- �w�b�_���擾�p
  ------------------------------
-- ���[���
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;   -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;        -- �S����
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12);   -- ���[ID
  gd_exec_date              DATE;           -- ���{��
--
  gt_body_data              tab_data_type_dtl;       -- �擾���R�[�h�\
  gt_check_data             tab_double_check;        -- ���R�[�h�`�F�b�N�p
  gt_xml_data_table         XML_DATA;                -- �w�l�k�f�[�^�^�O�\
--
--
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--###########################  �Œ蕔 END   ############################
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml';   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = gc_d) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END fnc_conv_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(H-1)
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
    cv_process_year   CONSTANT VARCHAR2(8)  := '�����N��';
    lc_f_day          CONSTANT VARCHAR2(3)  := '/01';
    lc_f_time         CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time         CONSTANT VARCHAR2(10) := ' 23:59:59';
-- 2008/10/15 v1.8 ADD START
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
-- 2008/10/15 v1.8 ADD END
--
    lc_prod           CONSTANT VARCHAR2(5)  := 'PROD';    -- ���Y�֘A
    lc_completed      CONSTANT NUMBER       := 1;         -- �����t���O�F����
    lc_material       CONSTANT NUMBER       := -1;        -- ����
    lc_product        CONSTANT NUMBER       := 1;         -- ���i
--
    -- *** ���[�J���E�ϐ� ***
-- 2008/10/15 v1.8 UPDATE START
    lv_select         VARCHAR2(10000);   -- ����SELECT
    --lv_from1          VARCHAR2(1000);   -- ����FROM
    --lv_order_by       VARCHAR2(100);    -- ����ORDER BY
    --lv_sql1           VARCHAR2(10000);  -- �f�[�^�擾�p�r�p�k�iREVERSE_ID��NULL�p�j
    lv_select_chk     VARCHAR2(10000);    -- �G���[�`�F�b�N�pSELECT
    --lv_group_by_chk   VARCHAR2(100);    -- �G���[�`�F�b�N�pGROUP BY
    lv_where1         VARCHAR2(1000);   -- ����WHERE
    lv_order          VARCHAR2(1000);    -- ����ORDER BY
    lv_group          VARCHAR2(1000);    -- ����ORDER BY
-- 2008/10/15 v1.8 UPDATE END
--
    lv_err_batch_no   VARCHAR2(3200) DEFAULT NULL;  -- �o�b�`�̃G���[�m��
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR;
    lc_ref ref_cursor;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ----------------------------------------------------
    -- ���t���擾
    -- ----------------------------------------------------
    -- �����N���E�J�n��
    gd_exec_start := FND_DATE.STRING_TO_DATE(SUBSTR(ir_param.exec_year_month,1,4)
      || gc_sla || SUBSTR(ir_param.exec_year_month,5) || lc_f_day, gc_char_format);
    -- �G���[����
    IF ( gd_exec_start IS NULL ) THEN
      lv_errbuf := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_process_year
                                             ,'ERROR_VALUE'
                                             ,ir_param.exec_year_month ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
--
    -- �����N���E�I����
    gd_exec_end   := LAST_DAY(gd_exec_start);
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_e_time;
--
--
-- 2008/10/15 v1.8 ADD START
    -- ----------------------------------------------------
    -- �r�p�k�����i�G���[�`�F�b�N�p�j
    -- ----------------------------------------------------
    lv_select_chk :=
       '      SELECT /*+ leading ( itp1 gic1 mcb1 gic2 mcb2 gmd1 gbh1 grb1 ) */ '
    || '             gbh1.batch_no        batch_no ' -- �o�b�`�m��
    || '            ,count(gbh1.batch_no) cnt'       -- ���o�b�`�h�c�̌���
    || '      FROM'
    || '             ic_tran_pnd               itp1'  -- �ۗ��݌Ƀg�����U�N�V����(�����p)
    || '            ,gmi_item_categories       gic1'
    || '            ,mtl_categories_b          mcb1'
    || '            ,gmi_item_categories       gic2'
    || '            ,mtl_categories_b          mcb2'
    || '            ,gme_material_details      gmd1'
    || '            ,gme_batch_header          gbh1'
    || '            ,gmd_routings_b            grb1'
    || '            ,xxcmn_rcv_pay_mst         xrpm1' -- �󕥃}�X�^
    || '            ,gme_material_details      gmd2'
    || '            ,gme_batch_header          gbh2'
    || '            ,gmd_routings_b            grb2'
    || '            ,xxcmn_rcv_pay_mst         xrpm2' -- �󕥃}�X�^
    || '            ,ic_tran_pnd               itp2'  -- �ۗ��݌Ƀg�����U�N�V����(���i�p)
    || '      WHERE  itp1.doc_type         = ''' || lc_prod || ''''
    || '      AND    itp1.completed_ind   = ''' || lc_completed || ''''    -- ����
    || '      AND    itp1.trans_date      >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''',''' || gc_char_dt_format || ''')'
    || '      AND    itp1.trans_date      <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end  || ''',''' || gc_char_dt_format || ''')'
    || '      AND    itp1.line_type       = ''' || lc_product || ''''
    || '      AND    itp1.reverse_id      IS NULL'
    || '      AND    gic1.item_id         = itp1.item_id'
    || '      AND    gic1.category_set_id = ''' || cn_prod_class_id || ''''
    || '      AND    mcb1.category_id     = gic1.category_id'
    || '      AND    mcb1.segment1        = ''' || ir_param.goods_class || ''''
    || '      AND    gic2.item_id         = itp1.item_id'
    || '      AND    gic2.category_set_id = ''' || cn_item_class_id || ''''
    || '      AND    mcb2.category_id     = gic2.category_id'
    || '      AND    mcb2.segment1        = ''' || ir_param.item_class || ''''
    || '      AND    gmd1.batch_id        = itp1.doc_id'
    || '      AND    gmd1.line_no         = itp1.doc_line'
    || '      AND    gbh1.batch_id        = gmd1.batch_id'
    || '      AND    grb1.routing_id      = gbh1.routing_id'
    || '      AND    xrpm1.doc_type       = itp1.doc_type'
    || '      AND    xrpm1.line_type      = itp1.line_type'
    || '      AND    xrpm1.routing_class  = grb1.routing_class'
    || '      AND    xrpm1.line_type      = gmd1.line_type'
    || '      AND    xrpm1.break_col_08 IS NOT NULL'
    || '      AND    (((gmd1.attribute5 IS NULL) AND (xrpm1.hit_in_div IS NULL))'
    || '             OR (xrpm1.hit_in_div = gmd1.attribute5))'
    || '      AND    ((xrpm1.routing_class <> ''70'')'
    || '             OR (xrpm1.routing_class = ''70'''
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd3'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd3.batch_id   = gmd1.batch_id'
    || '                              AND    gmd3.line_no    = gmd1.line_no'
    || '                              AND    gmd3.line_type  = -1'
    || '                              AND    gic.item_id     = gmd3.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm1.item_div_origin))'
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd4'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd4.batch_id   = gmd1.batch_id'
    || '                              AND    gmd4.line_no    = gmd1.line_no'
    || '                              AND    gmd4.line_type  = 1'
    || '                              AND    gic.item_id     = gmd4.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm1.item_div_ahead)))'
    || '             )'
    || '      AND    gmd2.batch_id        = itp2.doc_id'
    || '      AND    gmd2.line_no         = itp2.doc_line'
    || '      AND    gbh2.batch_id        = gmd2.batch_id'
    || '      AND    grb2.routing_id      = gbh2.routing_id'
    || '      AND    xrpm2.doc_type       = itp2.doc_type'
    || '      AND    xrpm2.line_type      = itp2.line_type'
    || '      AND    xrpm2.routing_class  = grb2.routing_class'
    || '      AND    xrpm2.line_type      = gmd2.line_type'
    || '      AND    xrpm2.break_col_08 IS NOT NULL'
    || '      AND    (((gmd2.attribute5 IS NULL) AND (xrpm2.hit_in_div IS NULL))'
    || '             OR (xrpm2.hit_in_div = gmd2.attribute5))'
    || '      AND    ((xrpm2.routing_class <> ''70'')'
    || '             OR (xrpm2.routing_class = ''70'''
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd5'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd5.batch_id   = gmd2.batch_id'
    || '                              AND    gmd5.line_no    = gmd2.line_no'
    || '                              AND    gmd5.line_type  = -1'
    || '                              AND    gic.item_id     = gmd2.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm2.item_div_origin))'
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd6'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd6.batch_id   = gmd2.batch_id'
    || '                              AND    gmd6.line_no    = gmd2.line_no'
    || '                              AND    gmd6.line_type  = 1'
    || '                              AND    gic.item_id     = gmd6.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm2.item_div_ahead)))'
    || '             )'
    || '      AND    itp1.doc_id          = itp2.doc_id'
    || '      AND    itp2.doc_type        = ''' || lc_prod || ''''
    || '      AND    itp2.completed_ind   = ''' || lc_completed || ''''  -- ����
    || '      AND    itp2.line_type       = ''' || lc_material || ''''   -- ���i
    || '      AND    itp2.reverse_id      IS NULL';
--
    -- ----------------------------------------------------
    -- �r�p�k����
    -- ----------------------------------------------------
    lv_select :=
       '      SELECT /*+ leading ( itp1 gic1 mcb1 gic2 mcb2 gmd1 gbh1 grb1 ) */'
    || '             iimb1.item_no                           item_code'           -- �ԕi�����i�ڃR�[�h
    || '            ,ximb1.item_short_name                   item_name'           -- �ԕi�����i�ږ���
    || '            ,iimb2.item_no                           product_item_code'   -- ���i�i�ڃR�[�h
    || '            ,ximb2.item_short_name                   product_item_name'   -- ���i�i�ږ���
    || '            ,itp1.trans_qty * TO_NUMBER(xrpm1.rcv_pay_div) quantity'      -- �������
-- 2008/11/11 v1.9 UPDATE START
--    || '            ,xsupv1.stnd_unit_price_gen               standard_cost'      -- �W������
    || '            ,xsupv1.stnd_unit_price                  standard_cost'      -- �W������
-- 2008/11/11 v1.9 UPDATE END
    || '            ,itp2.trans_qty * TO_NUMBER(xrpm1.rcv_pay_div) turn_qty'           -- �����
    || '            ,TO_NUMBER(NVL('
    || '               (SELECT fmd2.attribute5'
    || '                FROM   fm_matl_dtl               fmd2'     -- �t�H�[�~�����f�B�e�[��
    || '                WHERE  fmd2.formula_id = gbh2.formula_id'  -- �O������������
    || '                AND    fmd2.line_type  = xrpm2.line_type'  -- �O������������
    || '                AND    fmd2.line_no    = gmd2.line_no'     -- �O������������
    || '               )'
    || '             ,0))       turn_price'         -- ��P��
    || '      FROM   ic_tran_pnd              itp1'    -- �ۗ��݌Ƀg�����U�N�V����(�����p)
    || '            ,gmi_item_categories      gic1'
    || '            ,mtl_categories_b         mcb1'
    || '            ,gmi_item_categories      gic2'
    || '            ,mtl_categories_b         mcb2'
    || '            ,ic_item_mst_b            iimb1'
    || '            ,xxcmn_item_mst_b         ximb1'
    || '            ,gme_material_details     gmd1'
    || '            ,gme_batch_header         gbh1'
    || '            ,gmd_routings_b           grb1'
    || '            ,gme_material_details     gmd2'
    || '            ,gme_batch_header         gbh2'
    || '            ,gmd_routings_b           grb2'
    || '            ,ic_tran_pnd              itp2'    -- �ۗ��݌Ƀg�����U�N�V����(���i�p)
    || '            ,ic_item_mst_b            iimb2'
    || '            ,xxcmn_item_mst_b         ximb2'
    || '            ,xxcmn_rcv_pay_mst        xrpm1'  -- �󕥃}�X�^
    || '            ,xxcmn_rcv_pay_mst        xrpm2'  -- �󕥃}�X�^
--    || '            ,xxcmn_lookup_values_v    xlvv1'
    || '            ,xxcmn_stnd_unit_price_v  xsupv1'  -- �W���������VIEW
    || '      WHERE  itp1.doc_type           =  ''' || lc_prod || ''''
    || '      AND    itp1.completed_ind      =  ''' || lc_completed || ''''    -- ����
    || '      AND    itp1.trans_date         >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''',''' || gc_char_dt_format || ''')'
    || '      AND    itp1.trans_date         <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''','''|| gc_char_dt_format || ''')'
    || '      AND    itp1.line_type          =  ''' || lc_product || ''''
    || '      AND    itp1.reverse_id         IS NULL'
    || '      AND    gic1.item_id            = itp1.item_id'
    || '      AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '      AND    mcb1.category_id        = gic1.category_id'
    || '      AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''    -- ���[�t
    || '      AND    gic2.item_id            = itp1.item_id'
    || '      AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '      AND    mcb2.category_id        = gic2.category_id'
    || '      AND    mcb2.segment1           = ''' || ir_param.item_class || ''''     -- ����
    || '      AND    itp1.doc_id             = gmd1.batch_id'
    || '      AND    itp1.doc_line           = gmd1.line_no'
    || '      AND    gbh1.batch_id           = gmd1.batch_id'
    || '      AND    grb1.routing_id         = gbh1.routing_id'
 /**/
    || '      AND    itp2.doc_id             = gmd2.batch_id'
    || '      AND    itp2.doc_line           = gmd2.line_no'
    || '      AND    gbh2.batch_id           = gmd2.batch_id'
    || '      AND    grb2.routing_id         = gbh2.routing_id'
 /**/
    || '      AND    iimb1.item_id           = itp1.item_id'
    || '      AND    ximb1.item_id           = iimb1.item_id'
    || '      AND    ximb1.start_date_active <= TRUNC(itp1.trans_date)'
    || '      AND    ximb1.end_date_active   >= TRUNC(itp1.trans_date)'
    || '      AND    itp1.item_id            = xsupv1.item_id'
    || '      AND    xsupv1.start_date_active <= TRUNC(itp1.trans_date)'
    || '      AND    xsupv1.end_date_active   >= TRUNC(itp1.trans_date)'
    || '      AND    itp1.doc_type           = xrpm1.doc_type'
    || '      AND    itp1.line_type          = xrpm1.line_type'
    || '      AND    xrpm1.routing_class     = grb1.routing_class'
    || '      AND    xrpm1.line_type         = gmd1.line_type'
    || '      AND    xrpm1.break_col_08 IS NOT NULL'
    || '      AND    (((gmd1.attribute5 IS NULL) AND (xrpm1.hit_in_div IS NULL))'
    || '             OR ( xrpm1.hit_in_div = gmd1.attribute5))'
    || '      AND    ((xrpm1.routing_class <> ''70'')'
    || '             OR (xrpm1.routing_class = ''70'''
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd3'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd3.batch_id   = gmd1.batch_id'
    || '                            AND    gmd3.line_no    = gmd1.line_no'
    || '                            AND    gmd3.line_type  = -1'
    || '                            AND    gic.item_id     = gmd3.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm1.item_div_origin))'
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd4'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd4.batch_id   = gmd1.batch_id'
    || '                            AND    gmd4.line_no    = gmd1.line_no'
    || '                            AND    gmd4.line_type  = 1'
    || '                            AND    gic.item_id     = gmd4.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm1.item_div_ahead))))'
/**/
    || '      AND    itp2.doc_type           = xrpm2.doc_type'
    || '      AND    itp2.line_type          = xrpm2.line_type'
    || '      AND    xrpm2.routing_class     = grb2.routing_class'
    || '      AND    xrpm2.line_type         = gmd2.line_type'
    || '      AND    xrpm2.break_col_08 IS NOT NULL'
    || '      AND    (((gmd2.attribute5 IS NULL) AND (xrpm2.hit_in_div IS NULL))'
    || '             OR ( xrpm2.hit_in_div = gmd2.attribute5))'
    || '      AND    ((xrpm2.routing_class <> ''70'')'
    || '             OR (xrpm2.routing_class = ''70'''
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd5'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd5.batch_id   = gmd2.batch_id'
    || '                            AND    gmd5.line_no    = gmd2.line_no'
    || '                            AND    gmd5.line_type  = -1'
    || '                            AND    gic.item_id     = gmd5.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm2.item_div_origin))'
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd6'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd6.batch_id   = gmd2.batch_id'
    || '                            AND    gmd6.line_no    = gmd2.line_no'
    || '                            AND    gmd6.line_type  = 1'
    || '                            AND    gic.item_id     = gmd6.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm2.item_div_ahead))))'
/**/
--    || '      AND    xlvv1.lookup_type       = ''XXCMN_DEALINGS_DIV'''
--    || '      AND    xrpm1.dealings_div      = xlvv1.lookup_code'
    || '      AND    itp1.doc_id             = itp2.doc_id'
    || '      AND    itp2.doc_type           = ''' || lc_prod || ''''
    || '      AND    itp2.completed_ind      = ''' || lc_completed || ''''        -- ����
    || '      AND    itp2.line_type          = ''' || lc_material || ''''         -- ���i
    || '      AND    itp2.reverse_id         IS NULL'
    || '      AND    iimb2.item_id           = itp2.item_id'
    || '      AND    ximb2.item_id           = iimb2.item_id'
    || '      AND    ximb2.start_date_active <= TRUNC(itp2.trans_date)'
    || '      AND    ximb2.end_date_active   >= TRUNC(itp2.trans_date)';
--
    lv_order  := ' ORDER BY item_code, product_item_code';
    lv_group  := ' GROUP BY gbh1.batch_no';
    lv_where1 := ' AND xrpm1.dealings_div  = ''' || ir_param.rcv_pay_div || '''';
--
-- 2008/10/15 v1.8 ADD END
-- 2008/10/15 v1.8 DELETE START
    -- ����SELECT
/*    lv_select :=
          ' SELECT'
      ||  ' xleiv1.item_code                        item_code'          -- �ԕi�����i�ڃR�[�h
      ||  ',xleiv1.item_short_name                  item_name'          -- �ԕi�����i�ږ���
      ||  ',xleiv2.item_code                        product_item_code'  -- ���i�i�ڃR�[�h
      ||  ',xleiv2.item_short_name                  product_item_name'  -- ���i�i�ږ���
-- 2008/08/26 v1.7 UPDATE START
--      ||  ',itp1.trans_qty * (-1)                   quantity'           -- �������
      ||  ',itp1.trans_qty * TO_NUMBER(xrpmpv1.rcv_pay_div) quantity'   -- �������
-- 2008/08/26 v1.7 UPDATE END
      ||  ',xsupv.stnd_unit_price_gen               standard_cost'      -- �W������
      ||  ',itp2.trans_qty                          turn_qty'           -- �����
      ||  ',TO_NUMBER(NVL(fmd.attribute5, ''0''))   turn_price'         -- ��P��
      ;
--
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    -- ����FROM
    lv_from1 :=
          ' FROM'
      ||  ' ic_tran_pnd               itp1'     -- �ۗ��݌Ƀg�����U�N�V����(�����p)
      ||  ',ic_tran_pnd               itp2'     -- �ۗ��݌Ƀg�����U�N�V����(���i�p)
      ||  ',xxcmn_rcv_pay_mst_prod_v  xrpmpv1'  -- �󕥃r���[�F���Y�֘A(�����p)
      ||  ',xxcmn_rcv_pay_mst_prod_v  xrpmpv2'  -- �󕥃r���[�F���Y�֘A(���i�p)
      ||  ',xxcmn_lookup_values2_v    xlvv'     -- �N�C�b�N�R�[�h���VIEW2
      ||  ',xxcmn_lot_each_item_v     xleiv1'   -- ���b�g�ʕi�ڏ��VIEW(�����p)
      ||  ',xxcmn_lot_each_item_v     xleiv2'   -- ���b�g�ʕi�ڏ��VIEW(���i�p)
      ||  ',xxcmn_stnd_unit_price_v   xsupv'    -- �W���������VIEW
      ||  ',fm_matl_dtl               fmd'      -- �t�H�[�~�����f�B�e�[��
      ;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    -- ����WHERE
    lv_where1 :=
        ' WHERE itp1.doc_type         = ''' || lc_prod || ''' '
      ||  ' AND itp1.completed_ind    = ' || lc_completed     -- ����
      ||  ' AND itp1.line_type        = ' || lc_product      -- ����
      ||  ' AND itp1.trans_date       >= FND_DATE.STRING_TO_DATE('
      ||  '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
      ||  ' AND itp1.trans_date       <= FND_DATE.STRING_TO_DATE('
      ||  '''' || gv_exec_end   || ''', ''' || gc_char_dt_format || ''' )'
      ||  ' AND itp1.doc_type         = xrpmpv1.doc_type'
      ||  ' AND itp1.line_type        = xrpmpv1.line_type'
      ||  ' AND itp1.doc_id           = xrpmpv1.doc_id'
      ||  ' AND itp1.doc_line         = xrpmpv1.doc_line'
      ;
--
    -- �p�����[�^�A�󕥋敪�����͂���Ă���Ƃ��ɒǉ�
    IF (ir_param.rcv_pay_div IS NOT NULL)THEN
      lv_where1 := lv_where1
        ||  ' AND xrpmpv1.dealings_div  = ''' || ir_param.rcv_pay_div || ''' '  -- �ԕi����
        ;
    END IF;
--
    -- ����WHERE����
    lv_where1 := lv_where1
      ||  ' AND itp1.item_id          = xleiv1.item_id'
      ||  ' AND itp1.lot_id           = xleiv1.lot_id'
      ||  ' AND (  (xleiv1.start_date_active IS NULL)'
      ||  '     OR (xleiv1.start_date_active <= TRUNC(itp1.trans_date)) )'
      ||  ' AND (  (xleiv1.end_date_active   IS NULL)'
      ||  '     OR (xleiv1.end_date_active   >= TRUNC(itp1.trans_date)) )'
      ||  ' AND xleiv1.item_div       = ''' || ir_param.goods_class || ''' ' -- ���[�t
      ||  ' AND xleiv1.prod_div       = ''' || ir_param.item_class || ''' '  -- ����
      ||  ' AND xlvv.lookup_type      = ''XXCMN_MONTH_TRANS_OUTPUT_FLAG'' '
      ||  ' AND xrpmpv1.dealings_div  = xlvv.meaning'
      ||  ' AND (  (xlvv.start_date_active IS NULL)'
      ||  '     OR (xlvv.start_date_active <= TRUNC(itp1.trans_date)) )'
      ||  ' AND (  (xlvv.end_date_active   IS NULL)'
      ||  '     OR (xlvv.end_date_active   >= TRUNC(itp1.trans_date)) )'
      ||  ' AND xlvv.language         = ''' || gv_ja || ''' '
      ||  ' AND xlvv.source_lang      = ''' || gv_ja || ''' '
      ||  ' AND xlvv.attribute8       IS NOT NULL'
      ||  ' AND itp1.item_id          = xsupv.item_id'
      ||  ' AND (  (xsupv.start_date_active IS NULL)'
      ||  '     OR (xsupv.start_date_active <= TRUNC(itp1.trans_date)) )'
      ||  ' AND (  (xsupv.end_date_active   IS NULL)'
      ||  '     OR (xsupv.end_date_active   >= TRUNC(itp1.trans_date)) )'
      ||  ' AND itp1.doc_id           = itp2.doc_id'
      ||  ' AND itp2.doc_type         = ''' || lc_prod || ''' '
      ||  ' AND itp2.completed_ind    = ' || lc_completed     -- ����
      ||  ' AND itp2.line_type        = ' || lc_material       -- ���i
      ||  ' AND itp2.item_id          = xleiv2.item_id'
      ||  ' AND itp2.lot_id           = xleiv2.lot_id'
      ||  ' AND itp2.reverse_id       IS NULL'
      ||  ' AND (  (xleiv2.start_date_active IS NULL)'
      ||  '     OR (xleiv2.start_date_active <= TRUNC(itp2.trans_date)) )'
      ||  ' AND (  (xleiv2.end_date_active   IS NULL)'
      ||  '     OR (xleiv2.end_date_active   >= TRUNC(itp2.trans_date)) )'
      ||  ' AND itp2.doc_type         = xrpmpv2.doc_type'
      ||  ' AND itp2.line_type        = xrpmpv2.line_type'
      ||  ' AND itp2.doc_id           = xrpmpv2.doc_id'
      ||  ' AND itp2.doc_line         = xrpmpv2.doc_line'
      ||  ' AND xrpmpv2.formula_id    = fmd.formula_id(+)'
      ||  ' AND xrpmpv2.line_type     = fmd.line_type(+)'
      ||  ' AND xrpmpv2.doc_line      = fmd.line_no(+)'
      ||  ' AND itp1.reverse_id       IS NULL'
      ;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q �a�x�吶��
    -- ----------------------------------------------------
    -- ����ORDER BY
    lv_order_by := ' ORDER BY'
                || ' item_code'
                || ',product_item_code'
                ;
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶���i�G���[�`�F�b�N�p�j
    -- ----------------------------------------------------
    lv_select_chk :=
          ' SELECT'
      ||  ' xrpmpv1.batch_no        batch_no' -- �o�b�`�m��
      ||  ',count(xrpmpv1.batch_no) cnt'      -- ���o�b�`�h�c�̌���
      ;
--
    -- ----------------------------------------------------
    -- �f�q�n�t�o �a�x�吶���i�G���[�`�F�b�N�p�j
    -- ----------------------------------------------------
    lv_group_by_chk := ' GROUP BY xrpmpv1.batch_no';
--
    -- ----------------------------------------------------
    -- �r�p�k�����i�G���[�`�F�b�N�p�j
    -- ----------------------------------------------------
--
    lv_sql1 := lv_select_chk || lv_from1 || lv_where1 || lv_group_by_chk;*/
-- 2008/10/15 v1.8 DELETE END
--
    -- ----------------------------------------------------
    -- ���i�E�������������݂���ꍇ�̓G���[
    -- (���i�ƌ����̂ǂ��炩���������݂���ꍇ�́A�����o�b�`�h�c����������)
    -- ----------------------------------------------------
--
-- 2008/10/15 v1.8 UPDATE START
    -- �p�����[�^�A�󕥋敪�����͂���Ă���Ƃ��ɒǉ�
    IF (ir_param.rcv_pay_div IS NOT NULL) THEN
      lv_select_chk := lv_select_chk || lv_where1;
    END IF;
--
    -- GROUP BY��̒ǉ�
    lv_select_chk := lv_select_chk || lv_group;
--
    -- �I�[�v��
    --OPEN lc_ref FOR  lv_sql1;
    OPEN lc_ref FOR  lv_select_chk;
-- 2008/10/15 v1.8 UPDATE END
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO gt_check_data;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref;
--
    <<check_loop>>
    FOR i IN 1..gt_check_data.COUNT LOOP
      -- ���i�E�������������݂���ꍇ�̓G���[
      IF (gt_check_data(i).cnt > 1) THEN
        -- �G���[�̏ꍇ�o�b�`�m����ێ�
        IF (lv_err_batch_no IS NULL) THEN
          lv_err_batch_no := gt_check_data(i).batch_no;
        ELSIF (gt_check_data(i).batch_no != gt_check_data(i -1).batch_no) THEN
          lv_err_batch_no := lv_err_batch_no || ' ,' || gt_check_data(i).batch_no;
        END IF;
      END IF;
--
    END LOOP check_loop;
--
    -- �G���[����
    IF ( lv_err_batch_no IS NOT NULL ) THEN
      lv_errbuf := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10156'
                                             ,'BATCH_NO'
                                             ,lv_err_batch_no ) ;
      ov_retcode  := gv_status_warn;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
--
--
    -- ----------------------------------------------------
    -- �r�p�k����
    -- ----------------------------------------------------
-- 2008/10/15 v1.8 UPDATE START
    /*lv_sql1 := lv_select || lv_from1 || lv_where1;
    IF (lv_err_batch_no IS NOT NULL) THEN
        lv_sql1 := lv_sql1 ||  '  AND xrpmpv1.batch_no not in (' || lv_err_batch_no || ')';
    END IF;
    lv_sql1 := lv_sql1 || lv_order_by;*/
--
    -- �p�����[�^�A�󕥋敪�����͂���Ă���Ƃ��ɒǉ�
    IF (ir_param.rcv_pay_div IS NOT NULL) THEN
      lv_select := lv_select || lv_where1;
    END IF;
--
    -- �G���[���̃o�b�`No�����݂���ꍇ�ɒǉ�
    IF (lv_err_batch_no IS NOT NULL) THEN
        lv_select := lv_select || '  AND xrpm1.batch_no not in (' || lv_err_batch_no || ')';
    END IF;
--
    -- ORDER BY��̒ǉ�
    lv_select := lv_select || lv_order;
--
    -- ----------------------------------------------------
    -- �f�[�^���o
    -- ----------------------------------------------------
    -- �I�[�v��
    --OPEN lc_ref FOR  lv_sql1;
    OPEN lc_ref FOR  lv_select;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref;
-- 2008/10/15 v1.8 UPDATE END
--
--
  EXCEPTION

--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(H-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           VARCHAR2(100) DEFAULT '*';            -- �����l
    lc_break_null           VARCHAR2(100) DEFAULT '**';           -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_item_code            VARCHAR2(30) DEFAULT lc_break_init;   -- �i�ڃR�[�h
--
    -- ���׃f�[�^�v�Z�p
    ln_standard_amount      NUMBER;                               -- �W�����z(����)
    ln_turn_amount          NUMBER;                               -- ����z(����)
    ln_difference_price     NUMBER;                               -- �P������
    ln_differense_cost      NUMBER;                               -- ��������
--
    -- �����N���p
    lv_ship_to_date         VARCHAR2(20);
    ld_ship_to_date         DATE;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION;             -- �擾���R�[�h�Ȃ�
--
    ---------------------
    -- XML�^�O�}������
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR     --   �^�O�^�C�v  T:�^�O
                                                              -- D:�f�[�^
                                                              -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                              -- Z:�f�[�^(NULL�̏ꍇ0�\��)
       ,iv_name              IN        VARCHAR2               --   �^�O��
       ,iv_value             IN        VARCHAR2  DEFAULT NULL --   �^�O�f�[�^(�ȗ���
       ,in_lengthb           IN        NUMBER    DEFAULT NULL --   �������i�o�C�g�j(�ȗ���
       ,iv_index             IN        NUMBER    DEFAULT NULL --   �C���f�b�N�X(�ȗ���
      )
    IS
      -- *** ���[�J���ϐ� ***
      ln_xml_idx  NUMBER;
      ln_work     NUMBER;
      lv_work     VARCHAR2(32000);
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULL�̏ꍇ�^�O�������Ȃ��Ή�
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      --�C���f�b�N�X
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      lv_work := iv_value;
--
      --�^�O�Z�b�g
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(lv_work, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := lv_work ;         --Null�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_body_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_body_data.COUNT = 0 ) THEN
      RAISE no_data_expt;
--
    END IF;
--
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml(gc_t, 'user_info');
--
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[�h�c
    prc_set_xml(gc_d, 'report_id', gv_report_id);
--
    -- ���{��
    prc_set_xml(gc_d, 'exec_date', TO_CHAR(gd_exec_date, gc_char_dt_format));
--
    -- �S��������
    prc_set_xml(gc_d, 'exec_user_dept', gv_user_dept, 10);
--
    -- �S���Җ�
    prc_set_xml(gc_d, 'exec_user_name', gv_user_name, 14);
--
    -- �p�����[�^�E�����N��
    ld_ship_to_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month, gc_char_ym_format);
    lv_ship_to_date := TO_CHAR(ld_ship_to_date, gc_char_ym_jp_format);
    prc_set_xml(gc_d, 'ship_to_date', lv_ship_to_date);
--
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_set_xml(gc_t, '/user_info');
--
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml(gc_t, 'data_info');
--
    -- -----------------------------------------------------
    -- �i��L�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml(gc_t, 'lg_item');
--
    -- =====================================================
    -- ���׃f�[�^�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_body_data.COUNT LOOP
--
      -- =====================================================
      -- �����i�ڃR�[�h�u���C�N
      -- =====================================================
      -- �����i�ڃR�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_body_data(i).item_code, lc_break_null ) <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_code <> lc_break_init ) THEN
          ------------------------------
          -- �����i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml(gc_t, '/lg_line');
--
          ------------------------------
          -- �����i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml(gc_t, '/g_item');
--
        END IF ;
--
        ------------------------------
        -- �����i�ڃR�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml(gc_t, 'g_item');
--
        -- -----------------------------------------------------
        -- �����i�ڃR�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �����i�ڃR�[�h
        prc_set_xml(gc_d, 'item_code', gt_body_data(i).item_code);
--
        -- �����i�ږ���
        prc_set_xml(gc_d, 'item_name', gt_body_data(i).item_name, 20);
--
        ------------------------------
        -- ���׃��C���k�f�J�n�^�O
        ------------------------------
        prc_set_xml(gc_t, 'lg_line');
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_code  := NVL( gt_body_data(i).item_code, lc_break_null );
--
      END IF;
--
      ------------------------------
      -- ���׃��C���k�f�J�n�^�O
      ------------------------------
      prc_set_xml(gc_t, 'g_line');
--
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���i�i�ڃR�[�h
      prc_set_xml(gc_d, 'product_item_code', gt_body_data(i).product_item_code);
--
      -- ���i�i�ږ���
      prc_set_xml(gc_d, 'product_item_name', gt_body_data(i).product_item_name, 20);
--
      -- �������(����)
      prc_set_xml(gc_z, 'quantity', gt_body_data(i).quantity);
--
      -- �W������(����)
      prc_set_xml(gc_z, 'standard_cost', gt_body_data(i).standard_cost);
--
      -- �W�����z(����) �F�������(����)�~�W������(����)
-- 2008/11/11 v1.9 UPDATE START
      --ln_standard_amount  := gt_body_data(i).quantity * gt_body_data(i).standard_cost;
      ln_standard_amount  := ROUND(gt_body_data(i).quantity * gt_body_data(i).standard_cost);
-- 2008/11/11 v1.9 UPDATE END
      prc_set_xml(gc_z, 'standard_amount', ln_standard_amount);
--
      -- ��P��(���i)
      prc_set_xml(gc_z, 'turn_price', gt_body_data(i).turn_price);
--
      -- ����z(����)
-- 2008/11/11 v1.9 UPDATE START
      --ln_turn_amount  := gt_body_data(i).turn_price * gt_body_data(i).turn_qty;
      ln_turn_amount  := ROUND(gt_body_data(i).turn_price * gt_body_data(i).turn_qty);
-- 2008/11/11 v1.9 UPDATE END
      prc_set_xml(gc_z, 'turn_amount', ln_turn_amount);
--
      -- �P������
      ln_difference_price := gt_body_data(i).turn_price - gt_body_data(i).standard_cost;
      prc_set_xml(gc_z, 'difference_price', ln_difference_price);
--
      -- ��������
      ln_differense_cost  := ln_turn_amount - ln_standard_amount;
      prc_set_xml(gc_z, 'difference_cost', ln_differense_cost);
--
--
      ------------------------------
      -- ���׃��C���f�I���^�O
      ------------------------------
      prc_set_xml(gc_t, '/g_line');
--
    END LOOP main_data_loop;
--
    ------------------------------
    -- ���׃��C���k�f�I���^�O
    ------------------------------
    prc_set_xml(gc_t, '/lg_line');
--
    ------------------------------
    -- �i�ڂf�I���^�O
    ------------------------------
    prc_set_xml(gc_t, '/g_item');
--
    ------------------------------
    -- �i�ڂk�f�I���^�O
    ------------------------------
    prc_set_xml(gc_t, '/lg_item');
--
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    prc_set_xml(gc_t, '/data_info');
--
--
    IF ( lv_retcode = gv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' );
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
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_date            IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class        IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class           IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_rcv_pay_div          IN     VARCHAR2    -- 04 : �󕥋敪
     ,ov_errbuf               OUT    VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              OUT    VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               OUT    VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'submain'; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000);                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gv_report_id  := 'XXCMN770008T';                              -- ���[ID
    gd_exec_date  := SYSDATE;                                     -- ���{��
    gv_user_dept  := xxcmn_common_pkg.get_user_dept(gn_user_id);  -- �S��������
    gv_user_name  := xxcmn_common_pkg.get_user_name(gn_user_id);  -- �S���Җ�
--
    lr_param_rec.exec_year_month := iv_proc_date;           -- 01 : �����N���i�K�{)
    lr_param_rec.goods_class     := iv_product_class;       -- 02 : ���i�敪�i�K�{)
    lr_param_rec.item_class      := iv_item_class;          -- 03 : �i�ڋ敪�i�K�{)
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;         -- 04 : �󕥋敪�i�C��)
--
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' );
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>');
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' );
--
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          );
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string );
      END LOOP xml_data_table;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' );
--
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf              OUT    VARCHAR2    -- �G���[���b�Z�[�W
     ,retcode             OUT    VARCHAR2    -- �G���[�R�[�h
     ,iv_proc_date        IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class    IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class       IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_rcv_pay_div      IN     VARCHAR2    -- 04 : �󕥋敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000);      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_proc_date            => iv_proc_date           -- 01 : �����N��
       ,iv_product_class        => iv_product_class       -- 02 : ���i�敪
       ,iv_item_class           => iv_item_class          -- 03 : �i�ڋ敪
       ,iv_rcv_pay_div          => iv_rcv_pay_div         -- 04 : �󕥋敪
       ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W
       ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h#
       ,ov_errmsg               => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn770008c;
/
