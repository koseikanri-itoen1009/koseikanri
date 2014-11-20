CREATE OR REPLACE PACKAGE BODY xxcmn820021c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820021c(body)
 * Description      : �������ٕ\�쐬
 * MD.050/070       : �W�������}�X�^Issue1.0(T_MD050_BPO_820)
 *                    �������ٕ\�쐬Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
 * Version          : 1.6
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_initialize              PROCEDURE : �O���[�o���ϐ��̕ҏW���s���B
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_xml_data_param   PROCEDURE : �^�O�o�� - �p�����[�^���
 *  prc_create_xml_data_dtl     PROCEDURE : �^�O�o�� - ���׏��
 *  prc_create_xml_data_typ     PROCEDURE : �^�O�o�� - ��ڌv���
 *  prc_create_xml_data_itm_dtl PROCEDURE : �^�O�o�� - �i�ڏ��i���חp�j
 *  prc_create_xml_data_vnd_dtl PROCEDURE : �^�O�o�� - �������i���חp�j
 *  prc_create_xml_data_s_dtl   PROCEDURE : �^�O�o�� - ���ڌv���
 *  prc_create_xml_data_itm     PROCEDURE : �^�O�o�� - �i�ڏ��
 *  prc_create_xml_data_vnd     PROCEDURE : �^�O�o�� - �������
 *  prc_create_xml_data_dpt     PROCEDURE : �^�O�o�� - �������
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/10    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/05/20    1.1   Masayuki Ikeda   �����ύX�v��#113�Ή�
 *  2008/06/10    1.2   Kazuo Kumamoto   �����e�X�g��Q�Ή�(Null�l�ɂ��e���v���[�g���G���[�Ή�)
 *  2008/06/24    1.3   Kazuo Kumamoto   ��Q�Ή�
 *                                       (1.3.1)�V�X�e���e�X�g��Q�Ή�(�d���W���P���w�b�_���o�����ǉ�)
 *                                       (1.3.2)�����e�X�g��Q�Ή�(�w�b�_�����̃y�[�W���o�͂����s��̏C��)
 *                                       (1.3.3)�����e�X�g��Q�Ή�(���������̎Z�o���@�ύX)
 *  2008/06/30    1.4   Kazuo Kumamoto   �V�X�e���e�X�g��Q�Ή�
 *                                       (1.4.1)�P�[�X���萔��1���ڂ����o�͂���Ȃ��s��Ή�
 *                                       (1.4.2)�u**���ڌv**�v���u���ڌv�v�Əo�͂����s��Ή�
 *  2008/07/01    1.5   Marushita        ST�s�339�Ή������������b�g�}�X�^����擾
 *  2008/07/02    1.6   Satoshi Yunba    �֑������Ή�
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
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXCMN820021C' ;   -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXCMN820021T' ;   -- ���[ID
--
  gc_language_code        CONSTANT VARCHAR2(2)  := 'JA' ;             -- ����LANGUAGE_CODE
  -- ������敪
  gc_temp_rcv_div_n       CONSTANT VARCHAR2(1)  := '0' ;              -- �ΏۊO
  gc_temp_rcv_div_y       CONSTANT VARCHAR2(1)  := '1' ;              -- �Ώ�
  -- �}�X�^�敪
  gc_price_type_s         CONSTANT VARCHAR2(1)  := '2' ;              -- �W��
  gc_price_type_r         CONSTANT VARCHAR2(1)  := '1' ;              -- ���ہi�d���j
  -- �d���P�����o���^�C�v
  gc_price_day_type_s     CONSTANT VARCHAR2(1)  := '1' ;              -- ������
  gc_price_day_type_n     CONSTANT VARCHAR2(1)  := '2' ;              -- �[����
  -- �Q�ƃ^�C�v
  gc_lookup_item_type     CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE' ;        -- ��ڋ敪
  gc_lookup_item_detail   CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_DETAIL_TYPE' ; -- ���ڋ敪
--
  -- �i�ڃJ�e�S����
  gc_cat_name_prod        CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_name_item        CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
  gc_cat_name_crowd       CONSTANT VARCHAR2(100) := '�Q�R�[�h' ;
--
  -- �G���[�R�[�h
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- �f�[�^�O�����b�Z�[�W
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ==================================================
  gv_sql_cmn_from       VARCHAR2(32000) ;   -- ���ʂe��������
  gv_sql_cmn_where      VARCHAR2(32000) ;   -- ���ʂv����������
--
--add start 1.3.2
  gv_dept_code          VARCHAR2(1000);
  gv_dept_name          VARCHAR2(1000);
--add end 1.3.2
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      output_type       VARCHAR2(20)    -- �o�͌`��
     ,fiscal_ym         VARCHAR2(6)     -- �Ώ۔N��
     ,prod_div          VARCHAR2(1)     -- ���i�敪
     ,item_div          VARCHAR2(1)     -- �i�ڋ敪
     ,dept_code         VARCHAR2(4)     -- �����R�[�h
     ,crowd_code_01     VARCHAR2(4)     -- �Q�R�[�h�P
     ,crowd_code_02     VARCHAR2(4)     -- �Q�R�[�h�Q
     ,crowd_code_03     VARCHAR2(4)     -- �Q�R�[�h�R
     ,item_code_01      VARCHAR2(7)     -- �i�ڃR�[�h�P
     ,item_code_02      VARCHAR2(7)     -- �i�ڃR�[�h�Q
     ,item_code_03      VARCHAR2(7)     -- �i�ڃR�[�h�R
     ,item_code_04      VARCHAR2(7)     -- �i�ڃR�[�h�S
     ,item_code_05      VARCHAR2(7)     -- �i�ڃR�[�h�T
     ,vendor_id_01      VARCHAR2(15)    -- �����h�c�P
     ,vendor_id_02      VARCHAR2(15)    -- �����h�c�Q
     ,vendor_id_03      VARCHAR2(15)    -- �����h�c�R
     ,vendor_id_04      VARCHAR2(15)    -- �����h�c�S
     ,vendor_id_05      VARCHAR2(15)    -- �����h�c�T
    ) ;
--
  TYPE rec_amount_data  IS RECORD 
    (
      s_unit_price   NUMBER   -- �W������
     ,r_unit_price   NUMBER   -- ���ی���
     ,d_unit_price   NUMBER   -- ��������
     ,s_amount       NUMBER   -- �W�����z
     ,r_amount       NUMBER   -- ���ۋ��z
     ,d_amount       NUMBER   -- ���z����
    ) ;

--
  TYPE ref_cursor IS REF CURSOR ;       -- REF_CURSOR�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gd_fiscal_date_from   DATE ;                -- �Ώ۔N��From
  gd_fiscal_date_to     DATE ;                -- �Ώ۔N��To
  gv_item_code          VARCHAR2(7) ;         -- �i�ڃR�[�h
  gv_item_name          VARCHAR2(20) ;        -- �i�ږ���
  gv_vendor_code        VARCHAR2(4) ;         -- �����R�[�h
  gv_vendor_name        VARCHAR2(20) ;        -- ����於��
  gv_type_code          VARCHAR2(4) ;         -- ��ڃR�[�h
  gv_type_name          VARCHAR2(20) ;        -- ��ږ���
  gv_uom                VARCHAR2(10) ;        -- �P��
  gv_case_quant         NUMBER ;              -- ����
  gv_quant              NUMBER := 0 ;         -- ����
  gv_quant_disp         NUMBER := 0 ;         -- ���ʁi�\���p�j
  gv_quant_dpt          NUMBER := 0 ;         -- ���ʁi�����v�j
--add start 1.4.1
  gv_save_case_quant    NUMBER := 0;
--add end 1.4.1
--
  gb_get_flg            BOOLEAN := FALSE ;    -- �f�[�^�擾����t���O
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER ;              -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
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
   * Procedure Name   : prc_initialize
   * Description      : �O���[�o���ϐ��̕ҏW���s���B
   ************************************************************************************************/
  PROCEDURE prc_initialize
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
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
  -- ==================================================
  -- �����N���̕ҏW
  -- ==================================================
  gd_fiscal_date_from   := FND_DATE.CANONICAL_TO_DATE( gr_param.fiscal_ym || '01' ) ;
  gd_fiscal_date_to     := LAST_DAY( gd_fiscal_date_from ) ;
--
  -- ==================================================
  -- ���ʂr�p�k���̕ҏW
  -- ==================================================
  gv_sql_cmn_from
    := '  ,xxpo_rcv_and_rtn_txns    xrart'
    || '  ,xxcmn_item_categories4_v xicv'
    ;
  gv_sql_cmn_where
    := ' AND   xrart.txns_date       BETWEEN :v1 AND :v2'
    || ' AND   xicv.item_id          = xrart.item_id'
    || ' AND   xicv.prod_class_code  = ''' || gr_param.prod_div || ''''
    || ' AND   xicv.item_class_code  = ''' || gr_param.item_div || ''''
    ;
  -- �p�����[�^�D�����ɓ��͂�����ꍇ
  IF  ( gr_param.dept_code IS NOT NULL )
  AND ( gr_param.dept_code <> xxcmn820011c.dept_code_all ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND   xrart.department_code = ''' || gr_param.dept_code || '''' ;
  END IF ;
  -- �p�����[�^�D�Q�R�[�h�̂����ꂩ�ɓ��͂�����ꍇ
  IF ( gr_param.crowd_code_01 IS NOT NULL )
  OR ( gr_param.crowd_code_02 IS NOT NULL )
  OR ( gr_param.crowd_code_03 IS NOT NULL ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND xicv.crowd_code IN( ''' || gr_param.crowd_code_01 || ''''
                            || '  ,''' || gr_param.crowd_code_02 || ''''
                            || '  ,''' || gr_param.crowd_code_03 || ''' )'
      ;
  END IF ;
  -- �p�����[�^�D�i�ڃR�[�h�̂����ꂩ�ɓ��͂�����ꍇ
  IF ( gr_param.item_code_01 IS NOT NULL )
  OR ( gr_param.item_code_02 IS NOT NULL )
  OR ( gr_param.item_code_03 IS NOT NULL )
  OR ( gr_param.item_code_04 IS NOT NULL )
  OR ( gr_param.item_code_05 IS NOT NULL ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND xrart.item_code IN( ''' || gr_param.item_code_01 || ''''
                            || '  ,''' || gr_param.item_code_02 || ''''
                            || '  ,''' || gr_param.item_code_03 || ''''
                            || '  ,''' || gr_param.item_code_04 || ''''
                            || '  ,''' || gr_param.item_code_05 || ''' )'
      ;
  END IF ;
  -- �p�����[�^�D�����h�c�̂����ꂩ�ɓ��͂�����ꍇ
  IF ( gr_param.vendor_id_01 IS NOT NULL )
  OR ( gr_param.vendor_id_02 IS NOT NULL )
  OR ( gr_param.vendor_id_03 IS NOT NULL )
  OR ( gr_param.vendor_id_04 IS NOT NULL )
  OR ( gr_param.vendor_id_05 IS NOT NULL ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND xrart.vendor_id IN( ' || NVL( gr_param.vendor_id_01, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_02, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_03, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_04, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_05, 'NULL' ) || ' )'
      ;
  END IF ;
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
  END prc_initialize ;
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml_data_user' ; -- �v���O������
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
    -- �J�n�^�O
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
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.output_type || 'T' ;
--
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
--
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- �I���^�O
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
   * Procedure Name   : prc_create_xml_data_param
   * Description      : �p�����[�^���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_param
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_param' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ���[�U�[�錾��
    -- ==================================================
    -- *** ���[�J���萔 ***
    lc_char_y       CONSTANT VARCHAR2(1200) := '�N' ;
    lc_char_m       CONSTANT VARCHAR2(1200) := '���x' ;
    lc_sql          CONSTANT VARCHAR2(1200)
      := ' SELECT mct.description'
      || ' FROM mtl_category_sets_tl   mcst'
      ||     ' ,mtl_category_sets_b    mcsb'
      ||     ' ,mtl_categories_b       mcb'
      ||     ' ,mtl_categories_tl      mct'
      || ' WHERE mct.source_lang        = ''' || gc_language_code || ''''
      || ' AND   mct.language           = ''' || gc_language_code || ''''
      || ' AND   mcb.category_id        = mct.category_id'
      || ' AND   mcb.segment1           = :v1'
      || ' AND   mcsb.structure_id      = mcb.structure_id'
      || ' AND   mcst.category_set_id   = mcsb.category_set_id'
      || ' AND   mcst.source_lang       = ''' || gc_language_code || ''''
      || ' AND   mcst.language          = ''' || gc_language_code || ''''
      || ' AND   mcst.category_set_name = :v2'
      ;
--
    -- *** ���[�J���ϐ� ***
    lv_prod_div_name        VARCHAR2(20) ;    -- ���i�敪����
    lv_item_div_name        VARCHAR2(20) ;    -- �i�ڋ敪����
--
    ex_no_data              EXCEPTION ;
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
    -- ���i�敪���̎擾
    BEGIN
      EXECUTE IMMEDIATE lc_sql
      INTO  lv_prod_div_name
      USING gr_param.prod_div
           ,gc_cat_name_prod
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE ex_no_data ;
    END ;
--
    -- �i�ڋ敪���̎擾
    BEGIN
      EXECUTE IMMEDIATE lc_sql
      INTO  lv_item_div_name
      USING gr_param.item_div
           ,gc_cat_name_item
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE ex_no_data ;
    END ;
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- �Ώ۔N��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_01' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gr_param.fiscal_ym, 1, 4 ) || lc_char_y
                                            || SUBSTRB( gr_param.fiscal_ym, 5, 2 ) || lc_char_m ;
    -- ���i�敪
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_02' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.prod_div ;
--
    -- ���i�敪����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_remarks_02' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_prod_div_name ;
--
    -- �i�ڋ敪
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_03' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.item_div ;
--
    -- �i�ڋ敪����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_remarks_03' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_item_div_name ;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN ex_no_data THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
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
  END prc_create_xml_data_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_dtl
   * Description      : ���׏��^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_dtl
    (
      iv_dept_code  IN    VARCHAR2    -- ���������R�[�h
     ,iv_item_id    IN    VARCHAR2    -- �i�ڂh�c
     ,iv_vendor_id  IN    VARCHAR2    -- �����h�c
     ,iv_item_type  IN    VARCHAR2    -- ��ڂh�c
     ,ov_errbuf     OUT   VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT   VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dtl' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    -- �Z�o����
    lr_amount               rec_amount_data ;
    -- ���׏o�͗p����
    lv_item_code          VARCHAR2(7) ;         -- �i�ڃR�[�h
    lv_item_name          VARCHAR2(20) ;        -- �i�ږ���
    lv_vendor_code        VARCHAR2(4) ;         -- �����R�[�h
    lv_vendor_name        VARCHAR2(20) ;        -- ����於��
    lv_uom                VARCHAR2(10) ;        -- �P��
    lv_case_quant         NUMBER ;              -- ����
    lv_type_code          VARCHAR2(4) ;         -- ��ڃR�[�h
    lv_type_name          VARCHAR2(20) ;        -- ��ږ���
    lv_quant              NUMBER ;              -- ����
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_main
      (
        p_type_id     xxpo_price_lines.expense_item_type%TYPE
       ,p_item_id     xxpo_rcv_and_rtn_txns.item_id%TYPE
       ,p_vendor_id   xxpo_rcv_and_rtn_txns.vendor_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT detail_code
            ,detail_name
            ,SUM( s_amount )  AS s_amount
            ,SUM( r_amount )  AS r_amount
      FROM
        (
          SELECT flv.attribute1         AS detail_code
                ,flv.meaning            AS detail_name
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS s_amount
                ,xrart.quantity * xpl.unit_price AS s_amount
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                ,0                                              AS r_amount
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type               = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xpl.expense_item_type = p_type_id
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          UNION ALL
          SELECT flv.attribute1         AS detail_code
                ,flv.meaning            AS detail_name
                ,0                                              AS s_amount
--mod start 1.3.3
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS r_amount
                ,xrart.quantity * xpl.unit_price AS r_amount
--mod end 1.3.3
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type               = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xpl.expense_item_type = p_type_id
          AND   xph.price_header_id   = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY detail_code
              ,detail_name
      ORDER BY detail_code
    ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���׏o�͗p���ڂ�ޔ�
    -- ====================================================
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR re_main IN cu_main
      (
        p_type_id     => iv_item_type
       ,p_item_id     => iv_item_id
       ,p_vendor_id   => iv_vendor_id
       ,p_dept_code   => iv_dept_code
      )
    LOOP
      -- ----------------------------------------------------
      -- �������ق��Z�o
      -- ----------------------------------------------------
      IF ( gv_quant = 0 ) THEN
        lr_amount.s_unit_price := 0 ;
        lr_amount.r_unit_price := 0 ; 
        lr_amount.d_unit_price := 0 ;
      ELSE
        lr_amount.s_unit_price := ROUND( re_main.s_amount / gv_quant, 2 ) ;
        lr_amount.r_unit_price := ROUND( re_main.r_amount / gv_quant, 2 ) ; 
        lr_amount.d_unit_price := lr_amount.s_unit_price - lr_amount.r_unit_price ;
      END IF ;
      lr_amount.s_amount     := re_main.s_amount ;
      lr_amount.r_amount     := re_main.r_amount ;
      lr_amount.d_amount     := re_main.s_amount - re_main.r_amount ;
--
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �f�[�^�^�O�o��
      -- ----------------------------------------------------
      -- �i�ڕʎ����ʕ\�̏ꍇ
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                   ,xxcmn820011c.program_id_03 ) ) THEN   -- ���ׁF�i�ڕ�
--
        -- �����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_vendor_code ;
        -- ����於��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_vendor_name ;
--
      -- �����ʕi�ڕʕ\�̏ꍇ
      ELSE
--
        -- �����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_item_code ;
        -- ����於��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_item_name ;
--
      END IF ;
--
      -- �������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_disp ;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'uom' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_uom ;
      -- �P�[�X���萔
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_case_quant ;
      -- ��ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_type_code ;
      -- ��ږ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_type_name ;
      -- ���ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := re_main.detail_code ;
      -- ���ږ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := re_main.detail_name ;
--
      -- �W������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 's_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.s_unit_price ;
      -- ���ی���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.r_unit_price,0) ;
--mod end 1.2
      -- ��������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'd_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.d_unit_price,0) ;
--mod end 1.2
      -- �W�����z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 's_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.s_amount,0) ;
--mod end 1.2
      -- ���ۋ��z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.r_amount,0) ;
--mod end 1.2
      -- ���z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'd_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.d_amount,0) ;
--mod end 1.2
--
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �O���[�o���ϐ��N���A
      -- ----------------------------------------------------
      -- �ŏ��̂P���̂ݏo�͂��鍀�ڂ��N���A����B
      gv_item_code   := NULL ;    -- �i�ڃR�[�h
      gv_item_name   := NULL ;    -- �i�ږ���
      gv_vendor_code := NULL ;    -- �����R�[�h
      gv_vendor_name := NULL ;    -- ����於��
      gv_uom         := NULL ;    -- �P��
      gv_case_quant  := NULL ;    -- ����
      gv_type_code   := NULL ;    -- ��ڃR�[�h
      gv_type_name   := NULL ;    -- ��ږ���
      gv_quant_disp  := NULL ;    -- ���ʁi�\���p�j
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
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
  END prc_create_xml_data_dtl ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_typ
   * Description      : ��ڌv���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_typ
    (
      iv_dept_code  IN    VARCHAR2    -- ���������R�[�h
     ,iv_item_id    IN    VARCHAR2    -- �i�ڂh�c
     ,iv_vendor_id  IN    VARCHAR2    -- �����h�c
     ,ov_errbuf     OUT   VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT   VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_typ' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_main
      (
        p_item_id     xxpo_rcv_and_rtn_txns.item_id%TYPE
       ,p_vendor_id   xxpo_rcv_and_rtn_txns.vendor_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT type_id
            ,type_code
            ,type_name
      FROM
        (
          SELECT xpl.expense_item_type  AS type_id
                ,flv.attribute1         AS type_code
                ,flv.meaning            AS type_name
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_type = flv.lookup_code
          AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          UNION ALL
          SELECT xpl.expense_item_type  AS type_id
                ,flv.attribute1         AS type_code
                ,flv.meaning            AS type_name
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type      = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_type = flv.lookup_code
          AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY type_id
              ,type_code
              ,type_name
      ORDER BY type_code
    ;
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_typ' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR re_main IN cu_main
      (
        p_item_id     => iv_item_id
       ,p_vendor_id   => iv_vendor_id
       ,p_dept_code   => iv_dept_code
      )
    LOOP
--
        -- ----------------------------------------------------
        -- �J�n�^�O
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_typ' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �R�[�h�E���̂�ޔ�
        -- ----------------------------------------------------
        gv_type_code := re_main.type_code ;
        gv_type_name := re_main.type_name ;
--
        -- ====================================================
        -- ���׏��o��
        -- ====================================================
        prc_create_xml_data_dtl
          (
            iv_dept_code      => iv_dept_code
           ,iv_item_id        => iv_item_id
           ,iv_vendor_id      => iv_vendor_id
           ,iv_item_type      => re_main.type_id
           ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �I���^�O
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_typ' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_typ' ;
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
  END prc_create_xml_data_typ ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_itm_dtl
   * Description      : �i�ڏ��^�O�o�́i���חp�j
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_itm_dtl
    (
      iv_dept_code  IN    VARCHAR2    -- ���������R�[�h
     ,iv_vendor_id  IN    VARCHAR2    -- �����h�c
     ,ov_errbuf     OUT   VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT   VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_itm_dtl' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    -- �r�p�k�����p
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    TYPE ret_value IS RECORD 
      (
        item_id         ic_item_mst_b.item_id%TYPE            -- �i�ڂh�c
       ,item_code       ic_item_mst_b.item_no%TYPE            -- �i�ڃR�[�h
       ,item_name       xxcmn_item_mst_b.item_short_name%TYPE -- �i�ږ���
       ,uom             xxpo_rcv_and_rtn_txns.uom%TYPE        -- ����P��
       ,case_quant      ic_item_mst_b.attribute11%TYPE        -- ����
       ,quant           xxpo_rcv_and_rtn_txns.quantity%TYPE   -- �������
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�p�k�ҏW
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   iimc.item_id           AS item_id'     -- �i�ڂh�c
      || '  ,iimc.item_no           AS item_code'   -- �i�ڃR�[�h
      || '  ,ximc.item_short_name   AS item_name'   -- �i�ږ���
      || '  ,xrart.uom              AS uom'         -- �P��
      || '  ,iimc.attribute11       AS case_quant'  -- �P�[�X����
      || '  ,SUM( xrart.quantity )  AS quant'       -- �������
      ;
    lv_sql_from
      := ' FROM'
      || '   ic_item_mst_b          iimc'           -- �n�o�l�i�ڃ}�X�^
      || '  ,xxcmn_item_mst_b       ximc'           -- �n�o�l�A�h�I���i�ڃ}�X�^
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN ximc.start_date_active'
      || '                       AND     NVL( ximc.end_date_active, xrart.txns_date )'
      || ' AND iimc.item_id             = ximc.item_id'
      || ' AND xrart.item_id            = iimc.item_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || ' AND xrart.vendor_id          = :v4'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   xicv.crowd_code'
      || '  ,iimc.item_id'
      || '  ,iimc.item_no'
      || '  ,ximc.item_short_name'
      || '  ,xrart.uom'
      || '  ,iimc.attribute11'
      || ' ORDER BY'
      || '   xicv.crowd_code'   -- �Q�R�[�h
      || '  ,iimc.item_no'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,iv_vendor_id
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- ���חp���ڂ�ޔ�
      -- ----------------------------------------------------
      gv_item_code  := lr_ref.item_code ;         -- �i�ڃR�[�h
      gv_item_name  := lr_ref.item_name ;         -- �i�ږ���
      gv_uom        := lr_ref.uom ;               -- �P��
      gv_case_quant := lr_ref.case_quant ;        -- �P�[�X����
      gv_quant      := lr_ref.quant ;             -- ����
      gv_quant_disp := lr_ref.quant ;             -- ���ʁi�\���p�j
--
      -- ====================================================
      -- ��ڏ��o��
      -- ====================================================
      prc_create_xml_data_typ
        (
          iv_dept_code      => iv_dept_code
         ,iv_item_id        => lr_ref.item_id
         ,iv_vendor_id      => iv_vendor_id
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_itm_dtl ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_vnd_dtl
   * Description      : �������^�O�o�́i���חp�j
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_vnd_dtl
    (
      iv_dept_code  IN    VARCHAR2    -- ���������R�[�h
     ,iv_item_id    IN    VARCHAR2    -- �i�ڂh�c
     ,ov_errbuf     OUT   VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT   VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_vnd_dtl' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    -- �r�p�k�����p
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    TYPE ret_value IS RECORD 
      (
        vendor_id       po_vendors.vendor_id%TYPE             -- �����h�c
       ,vendor_code     po_vendors.segment1%TYPE              -- �����R�[�h
       ,vendor_name     po_vendors.vendor_name%TYPE           -- ����於��
       ,uom             xxpo_rcv_and_rtn_txns.uom%TYPE        -- �P��
       ,quant           xxpo_rcv_and_rtn_txns.quantity%TYPE   -- �������
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�p�k�ҏW
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   pv.vendor_id           AS vendor_id'     -- �����h�c
      || '  ,pv.segment1            AS vendor_code'   -- �����R�[�h
      || '  ,xv.vendor_short_name   AS vendor_name'   -- ����於��
      || '  ,xrart.uom              AS uom'           -- �P��
      || '  ,SUM( xrart.quantity )  AS quant'         -- �������
      ;
    lv_sql_from
      := ' FROM'
      || '   po_vendors    pv'    -- �d����}�X�^
      || '  ,xxcmn_vendors xv'    -- �d����A�h�I���}�X�^
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN xv.start_date_active'
      || '                       AND     NVL( xv.end_date_active, xrart.txns_date )'
      || ' AND pv.vendor_id             = xv.vendor_id'
      || ' AND xrart.vendor_id          = pv.vendor_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || ' AND xrart.item_id            = :v4'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   pv.vendor_id'
      || '  ,pv.segment1'
      || '  ,xv.vendor_short_name'
      || '  ,xrart.uom'
      || ' ORDER BY'
      || '   pv.segment1'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,iv_item_id
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vnd_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- ���חp���ڂ�ޔ�
      -- ----------------------------------------------------
      gv_vendor_code := lr_ref.vendor_code ;      -- �����R�[�h
      gv_vendor_name := lr_ref.vendor_name ;      -- ����於��
      gv_uom         := lr_ref.uom ;              -- �P��
      gv_quant       := lr_ref.quant ;            -- ����
      gv_quant_disp  := lr_ref.quant ;            -- ���ʁi�\���p�j
--
      -- ====================================================
      -- ��ڏ��o��
      -- ====================================================
--add start 1.4.1
      gv_case_quant := gv_save_case_quant;
--add end 1.4.1
      prc_create_xml_data_typ
        (
          iv_dept_code      => iv_dept_code
         ,iv_item_id        => iv_item_id
         ,iv_vendor_id      => lr_ref.vendor_id
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vnd_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_vnd_dtl ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_itm
   * Description      : �i�ڏ��^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_itm
    (
      iv_dept_code  IN    VARCHAR2    -- ���������R�[�h
     ,ov_errbuf     OUT   VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT   VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_itm' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
--mod start 1.4.2
--    lc_s_dtl_sct_name VARCHAR2(10) := '���ڌv' ;
    lc_s_dtl_sct_name VARCHAR2(14) := '�������ڌv����' ;
--mod end 1.4.2
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    -- �r�p�k�����p
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
    -- �Z�o����
    lr_amount_dif           rec_amount_data ;   -- �Z�o���ځF�������ٍ��v
    lr_amount_rcv           rec_amount_data ;   -- �Z�o���ځF��������v
    lr_amount_dtl           rec_amount_data ;   -- �Z�o���ځF���ڌv
--mod start 1.4.2
--    lv_s_dtl_sct_name       VARCHAR2(10) ;
    lv_s_dtl_sct_name       VARCHAR2(14) ;
--mod end 1.4.2
--add start 1.3.2
    lb_s_dtl                BOOLEAN; -- �������擾����
    lb_item_info            BOOLEAN;
--add end 1.3.2
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    -- �i�ڕʎ����ʕ\�p
    TYPE ret_value IS RECORD 
      (
        item_id         ic_item_mst_b.item_id%TYPE            -- �i�ڂh�c
       ,item_code       ic_item_mst_b.item_no%TYPE            -- �i�ڃR�[�h
       ,item_name       xxcmn_item_mst_b.item_short_name%TYPE -- �i�ږ���
       ,case_quant      ic_item_mst_b.attribute11%TYPE        -- �P�[�X����
       ,quant           NUMBER                                -- �������
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_sum_dtl
      (
        p_item_id     xxpo_rcv_and_rtn_txns.item_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT attribute1       AS item_detail
            ,meaning          AS item_detail_name
            ,SUM( s_amount )  AS s_amount
            ,SUM( r_amount )  AS r_amount
      FROM
        (
          SELECT flv.attribute1
                ,flv.meaning
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS s_amount
                ,xrart.quantity * xpl.unit_price AS s_amount
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                ,0                                              AS r_amount
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          UNION ALL
          SELECT flv.attribute1
                ,flv.meaning
                ,0                                              AS s_amount
--mod start 1.3.3
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS r_amount
                ,xrart.quantity * xpl.unit_price AS r_amount
--mod end 1.3.3
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY attribute1
              ,meaning
      ORDER BY attribute1
    ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�p�k�ҏW
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   iimc.item_id           AS item_id'     -- �i�ڂh�c
      || '  ,iimc.item_no           AS item_code'   -- �i�ڃR�[�h
      || '  ,ximc.item_short_name   AS item_name'   -- �i�ږ���
      || '  ,iimc.attribute11       AS case_quant'  -- �P�[�X����
      || '  ,SUM( xrart.quantity )  AS quant'       -- �������
      ;
    lv_sql_from
      := ' FROM'
      || '   ic_item_mst_b          iimc'           -- �n�o�l�i�ڃ}�X�^
      || '  ,xxcmn_item_mst_b       ximc'           -- �n�o�l�A�h�I���i�ڃ}�X�^
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN ximc.start_date_active'
      || '                       AND     NVL( ximc.end_date_active, xrart.txns_date )'
      || ' AND iimc.item_id             = ximc.item_id'
      || ' AND xrart.item_id            = iimc.item_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   xicv.crowd_code'
      || '  ,iimc.item_id'
      || '  ,iimc.item_no'
      || '  ,ximc.item_short_name'
      || '  ,iimc.attribute11'
      || ' ORDER BY'
      || '   xicv.crowd_code'   -- �Q�R�[�h
      || '  ,iimc.item_no'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
--
--del start 1.3.2 �����׃J�[�\���̉��Ɉړ�
--    -- ====================================================
--    -- ���X�g�O���[�v�J�n�^�O
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--del end 1.3.2
--
--add start 1.3.2
    lb_item_info := false;
--add end 1.3.2
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
--add start 1.3.2
      lb_s_dtl := FALSE;
      <<sum_dtl_data_loop>>
      FOR re_sum_dtl IN cu_sum_dtl
        (
          p_item_id    => lr_ref.item_id
         ,p_dept_code  => iv_dept_code
        )
      LOOP
--add end 1.3.2
      gb_get_flg := TRUE ;
--add start 1.3.2
      IF (cu_sum_dtl%ROWCOUNT = 1) THEN
--add end 1.3.2
--add start 1.3.2
        IF (lc_ref%ROWCOUNT = 1 AND cu_sum_dtl%ROWCOUNT = 1) THEN
          IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                      ,xxcmn820011c.program_id_02            -- ���v�F����ʕi�ڕ�
                                      ,xxcmn820011c.program_id_05            -- ���ׁF����ʎ�����
                                      ,xxcmn820011c.program_id_06) ) THEN    -- ���v�F����ʎ�����
            -- ====================================================
            -- �J�n�^�O
            -- ====================================================
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dpt' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      --
            -- ====================================================
            -- �f�[�^�^�O
            -- ====================================================
            -- ���������R�[�h
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_code ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_code ;
--mod end 1.3.2
            -- ������������
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_name ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_name ;
--mod end 1.3.2
          END IF;
          -- ====================================================
          -- ���X�g�O���[�v�J�n�^�O
          -- ====================================================
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          lb_item_info := TRUE;
        END IF;
--add end 1.3.2
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �f�[�^�^�O�o��
      -- ----------------------------------------------------
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
--
      -- ----------------------------------------------------
      -- ������ޔ�
      -- ----------------------------------------------------
      gv_case_quant := lr_ref.case_quant ;
--
      -- ----------------------------------------------------
      -- �i�ڌv���擾
      -- ----------------------------------------------------
      BEGIN
        SELECT SUM( s_dif_amount )  AS s_dif_amount
              ,SUM( s_rcv_amount )  AS s_rcv_amount
              ,SUM( r_dif_amount )  AS r_dif_amount
              ,SUM( r_rcv_amount )  AS r_rcv_amount
        INTO   lr_amount_dif.s_amount
              ,lr_amount_rcv.s_amount
              ,lr_amount_dif.r_amount
              ,lr_amount_rcv.r_amount
        FROM
          (
            SELECT CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN 
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END s_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN 
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END s_rcv_amount
                  ,0  AS r_dif_amount
                  ,0  AS r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns  xrart
                ,xxpo_price_headers     xph
                ,xxpo_price_lines       xpl
                ,xxcmn_lookup_values_v  flv
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_s
            AND   xrart.item_id         = xph.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.item_id         = lr_ref.item_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            UNION ALL
            SELECT 0  AS s_dif_amount
                  ,0  AS s_rcv_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns  xrart
                ,ic_item_mst_b          iimc
                ,po_headers_all         pha
                ,po_lines_all           pla
                ,xxpo_price_headers     xph
                ,xxpo_price_lines       xpl
                ,xxcmn_lookup_values_v  flv
                ,ic_lots_mst            ilm
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   DECODE( iimc.attribute20
                         ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                             , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                        )               BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
            AND   xph.supply_to_id IS NULL
--add end 1.3.1
            AND   xrart.item_id         = xph.item_id
            AND   pla.attribute3        = xph.futai_code
            AND   pla.attribute2        = xph.factory_code
            AND   xrart.source_document_line_num = pla.line_num
            AND   pha.po_header_id               = pla.po_header_id
            AND   xrart.source_document_number   = pha.segment1
            AND   xrart.item_id         = iimc.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.item_id         = lr_ref.item_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            AND   xrart.item_id         = ilm.item_id(+)
            AND   xrart.lot_number      = ilm.lot_no(+)
          )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_amount_dif.s_amount := 0 ;
          lr_amount_dif.r_amount := 0 ;
          lr_amount_rcv.s_amount := 0 ;
          lr_amount_rcv.r_amount := 0 ;
      END ;
--
      -- ----------------------------------------------------
      -- �������ق��Z�o
      -- ----------------------------------------------------
      IF ( lr_ref.quant = 0 ) THEN
        lr_amount_dif.s_unit_price := 0 ;
        lr_amount_rcv.r_unit_price := 0 ;
        lr_amount_dif.s_unit_price := 0 ;
        lr_amount_rcv.r_unit_price := 0 ;
        lr_amount_dif.d_unit_price := 0 ;
        lr_amount_rcv.d_unit_price := 0 ;
      ELSE
        lr_amount_dif.s_unit_price := ROUND( lr_amount_dif.s_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.s_unit_price := ROUND( lr_amount_rcv.s_amount / lr_ref.quant, 2 ) ; 
        lr_amount_dif.r_unit_price := ROUND( lr_amount_dif.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.r_unit_price := ROUND( lr_amount_rcv.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_dif.d_unit_price := lr_amount_dif.s_unit_price - lr_amount_dif.r_unit_price ;
        lr_amount_rcv.d_unit_price := lr_amount_rcv.s_unit_price - lr_amount_rcv.r_unit_price ;
      END IF ;
      lr_amount_dif.d_amount     := lr_amount_dif.s_amount     - lr_amount_dif.r_amount ;
      lr_amount_rcv.d_amount     := lr_amount_rcv.s_amount     - lr_amount_rcv.r_amount ;
--
      gv_quant_dpt  := gv_quant_dpt + lr_ref.quant ;  -- ���ʁi�����v�j
--
      -- ----------------------------------------------------
      -- �i�ڌv���ڂ��o��
      -- ----------------------------------------------------
      -- �������ٍ��v�F�W������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_unit_price,0) ;
--mod end 1.2
      -- �������ٍ��v�F���ی���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_unit_price,0) ;
--mod end 1.2
      -- �������ٍ��v�F��������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_unit_price,0) ;
--mod end 1.2
      -- �������ٍ��v�F�W�����z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_amount,0) ;
--mod end 1.2
      -- �������ٍ��v�F���ۋ��z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_amount,0) ;
--mod end 1.2
      -- �������ٍ��v�F���z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_amount,0) ;
--mod end 1.2
--
      -- ��������v�F�W������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_unit_price,0) ;
--mod end 1.2
      -- ��������v�F���ی���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_unit_price,0) ;
--mod end 1.2
      -- ��������v�F��������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_unit_price,0) ;
--mod end 1.2
      -- ��������v�F�W�����z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_amount,0) ;
--mod end 1.2
      -- ��������v�F���ۋ��z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_amount,0) ;
--mod end 1.2
      -- ��������v�F���z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_amount,0) ;
--mod end 1.2
--
      -- ====================================================
      -- ���ڌv�o��
      -- ====================================================
      lv_s_dtl_sct_name := lc_s_dtl_sct_name ;
--
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
--
      lb_s_dtl := TRUE;
      END IF;
--add end 1.3.2
--
--del start 1.3.2 �����C���J�[�\���̉��ֈړ�
--      <<sum_dtl_data_loop>>
--      FOR re_sum_dtl IN cu_sum_dtl
--        (
--          p_item_id    => lr_ref.item_id
--         ,p_dept_code  => iv_dept_code
--        )
--      LOOP
--del end 1.3.2
        -- ----------------------------------------------------
        -- �J�n�^�O
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �������ق��Z�o
        -- ----------------------------------------------------
        IF ( lr_ref.quant = 0 ) THEN
          lr_amount_dtl.s_unit_price := 0 ;
          lr_amount_dtl.r_unit_price := 0 ;
          lr_amount_dtl.d_unit_price := 0 ;
        ELSE
          lr_amount_dtl.s_unit_price := ROUND( re_sum_dtl.s_amount / lr_ref.quant, 2 ) ;
          lr_amount_dtl.r_unit_price := ROUND( re_sum_dtl.r_amount / lr_ref.quant, 2 ) ; 
          lr_amount_dtl.d_unit_price := lr_amount_dtl.s_unit_price - lr_amount_dtl.r_unit_price ;
        END IF ;
        lr_amount_dtl.s_amount     := re_sum_dtl.s_amount ;
        lr_amount_dtl.r_amount     := re_sum_dtl.r_amount ;
        lr_amount_dtl.d_amount     := re_sum_dtl.s_amount - re_sum_dtl.r_amount ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �w�b�_
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_sct_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_s_dtl_sct_name ;
        -- ���ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail ;
        -- ���ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail_name ;
--
        -- �W������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_unit_price,0) ;
--mod end 1.2
        -- ���ی���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_unit_price,0) ;
--mod end 1.2
        -- ��������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_unit_price,0) ;
--mod end 1.2
        -- �W�����z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_amount,0) ;
--mod end 1.2
        -- ���ۋ��z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_amount,0) ;
--mod end 1.2
        -- ���z����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_amount,0) ;
--mod end 1.2
--
        -- �w�b�_���o�͂���̂́A�ŏ��̂P���݂̂Ȃ̂ŁA�P���ړo�^��ɃN���A����B
        lv_s_dtl_sct_name := NULL ;
--
        -- ----------------------------------------------------
        -- �I���^�O
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      END LOOP sum_dtl_data_loop ;
--
--add start 1.3.2
      IF (lb_s_dtl) THEN
--add end 1.3.2
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ====================================================
      -- �������o��
      -- ====================================================
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                   ,xxcmn820011c.program_id_03 ) ) THEN   -- ���ׁF�i�ڕ�
--add start 1.4.1
        gv_save_case_quant := lr_ref.case_quant ;
--add end 1.4.1
        prc_create_xml_data_vnd_dtl
          (
            iv_dept_code      => iv_dept_code
           ,iv_item_id        => lr_ref.item_id
           ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
      END IF ;
--
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
      END IF;
--add end 1.3.2
--
    END LOOP main_data_loop ;
--
--mod start 1.3.2
--    -- ====================================================
--    -- ���X�g�O���[�v�I���^�O
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    IF (lb_item_info) THEN
      -- ====================================================
      -- ���X�g�O���[�v�I���^�O
      -- ====================================================
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                  ,xxcmn820011c.program_id_02            -- ���v�F����ʕi�ڕ�
                                  ,xxcmn820011c.program_id_05            -- ���ׁF����ʎ�����
                                  ,xxcmn820011c.program_id_06) ) THEN    -- ���v�F����ʎ�����
--
        -- ���ʁi�����v�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_dpt;
--
        gv_quant_dpt := 0 ;
--
        -- ====================================================
        -- �I���^�O
        -- ====================================================
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      END IF;
    END IF;
--mod end 1.3.2
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_itm ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_vnd
   * Description      : �������^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_vnd
    (
      iv_dept_code  IN    VARCHAR2    -- ���������R�[�h
     ,ov_errbuf     OUT   VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT   VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_vnd' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
--mod start 1.4.2
--    lc_s_dtl_sct_name VARCHAR2(10) := '���ڌv' ;
    lc_s_dtl_sct_name VARCHAR2(14) := '�������ڌv����' ;
--mod end 1.4.2
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    -- �r�p�k�����p
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
    -- �Z�o����
    lr_amount_dif           rec_amount_data ;   -- �Z�o���ځF�������ٍ��v
    lr_amount_rcv           rec_amount_data ;   -- �Z�o���ځF��������v
    lr_amount_dtl           rec_amount_data ;   -- �Z�o���ځF���ڌv
--mod start 1.4.2
--    lv_s_dtl_sct_name       VARCHAR2(10) ;
    lv_s_dtl_sct_name       VARCHAR2(14) ;
--mod end 1.4.2
--add start 1.3.2
    lb_s_dtl                BOOLEAN;
    lb_vnd_info             BOOLEAN;
--add end 1.3.2
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    -- �����ʕi�ڕʕ\�p
    TYPE ret_value IS RECORD 
      (
        vendor_id       po_vendors.vendor_id%TYPE       -- �����h�c
       ,vendor_code     po_vendors.segment1%TYPE        -- �����R�[�h
       ,vendor_name     po_vendors.vendor_name%TYPE     -- ����於��
       ,quant           NUMBER                          -- �������
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_sum_dtl
      (
        p_vendor_id   xxpo_rcv_and_rtn_txns.vendor_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT attribute1       AS item_detail
            ,meaning          AS item_detail_name
            ,SUM( s_amount )  AS s_amount
            ,SUM( r_amount )  AS r_amount
      FROM
        (
          SELECT flv.attribute1
                ,flv.meaning
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS s_amount
                ,xrart.quantity * xpl.unit_price AS s_amount
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                ,0                                              AS r_amount
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxcmn_item_categories4_v xicv
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xicv.item_id          = xrart.item_id
          AND   xicv.prod_class_code  = gr_param.prod_div
          AND   xicv.item_class_code  = gr_param.item_div
          AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
          UNION ALL
          SELECT flv.attribute1
                ,flv.meaning
                ,0                                              AS s_amount
--mod start 1.3.3
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS r_amount
                ,xrart.quantity * xpl.unit_price AS r_amount
--mod end 1.3.3
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxcmn_item_categories4_v xicv
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id          = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xicv.item_id          = xrart.item_id
          AND   xicv.prod_class_code  = gr_param.prod_div
          AND   xicv.item_class_code  = gr_param.item_div
          AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY attribute1
              ,meaning
      ORDER BY attribute1
    ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�p�k�ҏW
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   pv.vendor_id           AS vendor_id'     -- �����h�c
      || '  ,pv.segment1            AS vendor_code'   -- �����R�[�h
      || '  ,xv.vendor_short_name   AS vendor_name'   -- ����於��
      || '  ,SUM( xrart.quantity )  AS quant'         -- �������
      ;
    lv_sql_from
      := ' FROM'
      || '   po_vendors    pv'    -- �d����}�X�^
      || '  ,xxcmn_vendors xv'    -- �d����A�h�I���}�X�^
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN xv.start_date_active'
      || '                       AND     NVL( xv.end_date_active, xrart.txns_date )'
      || ' AND pv.vendor_id             = xv.vendor_id'
      || ' AND xrart.vendor_id          = pv.vendor_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   pv.vendor_id'
      || '  ,pv.segment1'
      || '  ,xv.vendor_short_name'
      || ' ORDER BY'
      || '   pv.segment1'
      ;
--
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
-- 
--del start 1.3.2 �����׃J�[�\���̉��Ɉړ�
--    -- ====================================================
--    -- ���X�g�O���[�v�J�n�^�O
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vnd_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--del end 1.3.2
--
--add start 1.3.2
    lb_vnd_info := FALSE;
--add end 1.3.2
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
--add start 1.3.2
      lb_s_dtl := FALSE;
      <<sum_dtl_data_loop>>
      FOR re_sum_dtl IN cu_sum_dtl
        (
          p_vendor_id   => lr_ref.vendor_id
         ,p_dept_code   => iv_dept_code
        )
      LOOP
--add end 1.3.2
      gb_get_flg := TRUE ;
--add start 1.3.2
      IF (cu_sum_dtl%ROWCOUNT = 1) THEN
--add end 1.3.2
--add start 1.3.2
        IF (lc_ref%ROWCOUNT = 1 AND cu_sum_dtl%ROWCOUNT = 1) THEN
          IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                      ,xxcmn820011c.program_id_02            -- ���v�F����ʕi�ڕ�
                                      ,xxcmn820011c.program_id_05            -- ���ׁF����ʎ�����
                                      ,xxcmn820011c.program_id_06) ) THEN    -- ���v�F����ʎ�����
            -- ====================================================
            -- �J�n�^�O
            -- ====================================================
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dpt' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      --
            -- ====================================================
            -- �f�[�^�^�O
            -- ====================================================
            -- ���������R�[�h
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_code ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_code ;
--mod end 1.3.2
            -- ������������
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_name ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_name ;
--mod end 1.3.2
          END IF;
          -- ====================================================
          -- ���X�g�O���[�v�J�n�^�O
          -- ====================================================
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vnd_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          lb_vnd_info := TRUE;
        END IF;
--add end 1.3.2
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �f�[�^�^�O�o��
      -- ----------------------------------------------------
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_code ;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_name ;
--
      -- ----------------------------------------------------
      -- �����v���擾
      -- ----------------------------------------------------
      BEGIN
        SELECT SUM( s_dif_amount ) AS s_dif_amount
              ,SUM( s_rcv_amount ) AS s_rcv_amount
              ,SUM( r_dif_amount ) AS r_dif_amount
              ,SUM( r_rcv_amount ) AS r_rcv_amount
        INTO   lr_amount_dif.s_amount
              ,lr_amount_rcv.s_amount
              ,lr_amount_dif.r_amount
              ,lr_amount_rcv.r_amount
        FROM
          (
            SELECT CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                          ELSE 0
                   END s_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END s_rcv_amount
                  ,0  AS r_dif_amount
                  ,0  AS r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns    xrart
                ,xxcmn_item_categories4_v xicv
                ,xxpo_price_headers       xph
                ,xxpo_price_lines         xpl
                ,xxcmn_lookup_values_v    flv
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_s
            AND   xrart.item_id         = xph.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.vendor_id       = lr_ref.vendor_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            AND   xicv.item_id          = xrart.item_id
            AND   xicv.prod_class_code  = gr_param.prod_div
            AND   xicv.item_class_code  = gr_param.item_div
            AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
            UNION ALL
            SELECT 0  AS s_dif_amount
                  ,0  AS s_rcv_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns    xrart
                ,xxcmn_item_categories4_v xicv
                ,ic_item_mst_b            iimc
                ,po_headers_all           pha
                ,po_lines_all             pla
                ,xxpo_price_headers       xph
                ,xxpo_price_lines         xpl
                ,xxcmn_lookup_values_v    flv
                ,ic_lots_mst              ilm
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   DECODE( iimc.attribute20
                         ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                             , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                        )               BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
            AND   xph.supply_to_id IS NULL
--add end 1.3.1
            AND   xrart.item_id         = xph.item_id
            AND   pla.attribute3        = xph.futai_code
            AND   pla.attribute2        = xph.factory_code
            AND   xrart.source_document_line_num = pla.line_num
            AND   pha.po_header_id               = pla.po_header_id
            AND   xrart.source_document_number   = pha.segment1
            AND   xrart.item_id         = iimc.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.vendor_id       = lr_ref.vendor_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            AND   xicv.item_id          = xrart.item_id
            AND   xicv.prod_class_code  = gr_param.prod_div
            AND   xicv.item_class_code  = gr_param.item_div
            AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
            AND   xrart.item_id         = ilm.item_id(+)
            AND   xrart.lot_number      = ilm.lot_no(+)
          )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_amount_dif.s_amount      := 0 ;
          lr_amount_dif.r_amount      := 0 ;
          lr_amount_rcv.s_amount      := 0 ;
          lr_amount_rcv.r_amount      := 0 ;
      END ;
      -- ----------------------------------------------------
      -- �������ق��Z�o
      -- ----------------------------------------------------
      IF ( lr_ref.quant = 0 ) THEN
        lr_amount_dif.s_unit_price := 0 ;
        lr_amount_rcv.s_unit_price := 0 ;
        lr_amount_dif.r_unit_price := 0 ;
        lr_amount_rcv.r_unit_price := 0 ;
        lr_amount_dif.d_unit_price := 0 ;
        lr_amount_rcv.d_unit_price := 0 ;
      ELSE
        lr_amount_dif.s_unit_price := ROUND( lr_amount_dif.s_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.s_unit_price := ROUND( lr_amount_rcv.s_amount / lr_ref.quant, 2 ) ; 
        lr_amount_dif.r_unit_price := ROUND( lr_amount_dif.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.r_unit_price := ROUND( lr_amount_rcv.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_dif.d_unit_price := lr_amount_dif.s_unit_price - lr_amount_dif.r_unit_price ;
        lr_amount_rcv.d_unit_price := lr_amount_rcv.s_unit_price - lr_amount_rcv.r_unit_price ;
      END IF ;
      lr_amount_dif.d_amount     := lr_amount_dif.s_amount     - lr_amount_dif.r_amount ;
      lr_amount_rcv.d_amount     := lr_amount_rcv.s_amount     - lr_amount_rcv.r_amount ;
--
      gv_quant_dpt  := gv_quant_dpt + lr_ref.quant ;  -- ���ʁi�����v�j
--
      -- �������ٍ��v�F�W������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_unit_price,0) ;
--mod end 1.2
      -- �������ٍ��v�F���ی���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_unit_price,0) ;
--mod end 1.2
      -- �������ٍ��v�F��������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_unit_price,0) ;
--mod end 1.2
      -- �������ٍ��v�F�W�����z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_amount,0) ;
--mod end 1.2
      -- �������ٍ��v�F���ۋ��z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_amount,0) ;
--mod end 1.2
      -- �������ٍ��v�F���z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_amount,0) ;
--mod end 1.2
--
      -- ��������v�F�W������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_unit_price,0) ;
--mod end 1.2
      -- ��������v�F���ی���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_unit_price,0) ;
--mod end 1.2
      -- ��������v�F��������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_unit_price,0) ;
--mod end 1.2
      -- ��������v�F�W�����z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_amount,0) ;
--mod end 1.2
      -- ��������v�F���ۋ��z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_amount,0) ;
--mod end 1.2
      -- ��������v�F���z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_amount,0) ;
--mod end 1.2
--
      -- ====================================================
      -- ���ڌv�o��
      -- ====================================================
      lv_s_dtl_sct_name := lc_s_dtl_sct_name ;
--
      -- ----------------------------------------------------
      -- �J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
--
      lb_s_dtl := TRUE;
      END IF;
--add end 1.3.2
--
--del start 1.3.2 �����C���J�[�\���̉��ֈړ�
--      <<sum_dtl_data_loop>>
--      FOR re_sum_dtl IN cu_sum_dtl
--        (
--          p_vendor_id   => lr_ref.vendor_id
--         ,p_dept_code   => iv_dept_code
--        )
--      LOOP
--del end 1.3.2
        -- ----------------------------------------------------
        -- �J�n�^�O
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �������ق��Z�o
        -- ----------------------------------------------------
        IF ( lr_ref.quant = 0 ) THEN
          lr_amount_dtl.s_unit_price := 0 ;
          lr_amount_dtl.r_unit_price := 0 ;
          lr_amount_dtl.d_unit_price := 0 ;
        ELSE
          lr_amount_dtl.s_unit_price := ROUND( re_sum_dtl.s_amount / lr_ref.quant, 2 ) ;
          lr_amount_dtl.r_unit_price := ROUND( re_sum_dtl.r_amount / lr_ref.quant, 2 ) ; 
          lr_amount_dtl.d_unit_price := lr_amount_dtl.s_unit_price - lr_amount_dtl.r_unit_price ;
        END IF ;
        lr_amount_dtl.s_amount     := re_sum_dtl.s_amount ;
        lr_amount_dtl.r_amount     := re_sum_dtl.r_amount ;
        lr_amount_dtl.d_amount     := re_sum_dtl.s_amount - re_sum_dtl.r_amount ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �w�b�_
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_sct_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_s_dtl_sct_name ;
        -- ���ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail ;
        -- ���ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail_name ;
--
        -- �W������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_unit_price,0) ;
--mod end 1.2
        -- ���ی���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_unit_price,0) ;
--mod end 1.2
        -- ��������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_unit_price,0) ;
--mod end 1.2
        -- �W�����z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_amount,0) ;
--mod end 1.2
        -- ���ۋ��z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_amount,0) ;
--mod end 1.2
        -- ���z����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_amount,0) ;
--mod end 1.2
--
        -- �w�b�_���o�͂���̂́A�ŏ��̂P���݂̂Ȃ̂ŁA�P���ړo�^��ɃN���A����B
        lv_s_dtl_sct_name := NULL ;
--
        -- ----------------------------------------------------
        -- �I���^�O
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      END LOOP sum_dtl_data_loop ;
--
--add start 1.3.2
      IF (lb_s_dtl) THEN
--add end 1.3.2
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ====================================================
      -- �i�ڏ��o�́i���ו\�̂݁j
      -- ====================================================
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_05            -- ���ׁF����ʎ�����
                                   ,xxcmn820011c.program_id_07 ) ) THEN   -- ���ׁF������
--
        prc_create_xml_data_itm_dtl
          (
            iv_dept_code      => iv_dept_code
           ,iv_vendor_id      => lr_ref.vendor_id
           ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_process_expt ;
        END IF ;
--
      END IF ;
--
      -- ----------------------------------------------------
      -- �I���^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
      END IF;
--add end 1.3.2
--
    END LOOP main_data_loop ;
--
--mod start 1.3.2
--    -- ====================================================
--    -- ���X�g�O���[�v�I���^�O
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vnd_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    IF (lb_vnd_info) THEN
      -- ====================================================
      -- ���X�g�O���[�v�I���^�O
      -- ====================================================
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vnd_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                  ,xxcmn820011c.program_id_02            -- ���v�F����ʕi�ڕ�
                                  ,xxcmn820011c.program_id_05            -- ���ׁF����ʎ�����
                                  ,xxcmn820011c.program_id_06) ) THEN    -- ���v�F����ʎ�����
--
        -- ���ʁi�����v�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_dpt;
--
        gv_quant_dpt := 0 ;
--
        -- ====================================================
        -- �I���^�O
        -- ====================================================
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      END IF;
    END IF;
--mod end 1.3.2
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_vnd ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_dpt
   * Description      : �������^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_dpt
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dpt' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lv_sql_select   VARCHAR2(1200) ;
    lv_sql_from     VARCHAR2(1200) ;
    lv_sql_where    VARCHAR2(1200) ;
    lv_sql_other    VARCHAR2(1200) ;
    lv_sql          VARCHAR2(32000) ;
--
    lc_ref      ref_cursor ;
--
    TYPE ret_value IS RECORD 
      (
        dept_code       hr_locations_all.location_code%TYPE   -- ���������R�[�h
       ,dept_name       hr_locations_all.description%TYPE     -- ������������
      ) ;
    lr_ref    ret_value ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�p�k�ҏW
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   hla.location_code       AS dept_code' -- ���������R�[�h
      || '  ,xla.location_short_name AS dept_name' -- ������������
      ;
    lv_sql_from
      := ' FROM'
      || '   hr_locations_all         hla'
      || '  ,xxcmn_locations_all      xla'
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date       BETWEEN xla.start_date_active'
                                || ' AND     NVL( xla.end_date_active, xrart.txns_date )'
      || ' AND hla.location_id       = xla.location_id'
      || ' AND xrart.department_code = hla.location_code'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   hla.location_code'
      || '  ,xla.location_short_name'
      || ' ORDER BY'
      || '   hla.location_code'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dpt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--add start 1.3.2
      gb_get_flg := FALSE ;
--add end 1.3.2
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
--del start 1.3.2
--      gb_get_flg := TRUE ;
--del end 1.3.2
--del start 1.3.2 ��prc_create_xml_data_itm��prc_create_xml_data_vnd�ֈړ�
--      -- ====================================================
--      -- �J�n�^�O
--      -- ====================================================
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dpt' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
----
--      -- ====================================================
--      -- �f�[�^�^�O
--      -- ====================================================
--      -- ���������R�[�h
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_code ;
--      -- ������������
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_name ;
--del end 1.3.2
--
--add start 1.3.2
      gv_dept_code := lr_ref.dept_code;
      gv_dept_name := lr_ref.dept_name;
--add end 1.3.2
      ------------------------------
      -- �i�ڕʎ����ʕ\�̏ꍇ
      ------------------------------
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_01              -- ���ׁF�����ʕi�ڕ�
                                   ,xxcmn820011c.program_id_02 ) ) THEN     -- ���v�F�����ʕi�ڕ�
--
        -- �i�ڏ��o�͏������Ăяo���B
        prc_create_xml_data_itm
          (
            iv_dept_code      => lr_ref.dept_code
           ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      ------------------------------
      -- �����ʕi�ڕʕ\�̏ꍇ
      ------------------------------
      ELSIF ( gr_param.output_type IN( xxcmn820011c.program_id_05           -- ���ׁF�����ʎ�����
                                      ,xxcmn820011c.program_id_06 ) ) THEN  -- ���v�F�����ʎ�����
--
        -- �������o�͏������Ăяo���B
        prc_create_xml_data_vnd
          (
            iv_dept_code      => lr_ref.dept_code
           ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END IF ;
--
--del start 1.3.2 ��prc_create_xml_data_itm��prc_create_xml_data_vnd�ֈړ�
--      -- ���ʁi�����v�j
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_dpt' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--      gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_dpt;
--
--      gv_quant_dpt := 0 ;
----
--      -- ====================================================
--      -- �I���^�O
--      -- ====================================================
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dpt' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--del end 1.3.2
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dpt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_dpt ;
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
      iv_output_type        IN     VARCHAR2         -- 01 : �o�͌`��
     ,iv_fiscal_ym          IN     VARCHAR2         -- 02 : �Ώ۔N��
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 04 : �i�ڋ敪
     ,iv_dept_code          IN     VARCHAR2         -- 05 : ��������
     ,iv_crowd_code_01      IN     VARCHAR2         -- 06 : �Q�R�[�h�P
     ,iv_crowd_code_02      IN     VARCHAR2         -- 07 : �Q�R�[�h�Q
     ,iv_crowd_code_03      IN     VARCHAR2         -- 08 : �Q�R�[�h�R
     ,iv_item_code_01       IN     VARCHAR2         -- 09 : �i�ڃR�[�h�P
     ,iv_item_code_02       IN     VARCHAR2         -- 10 : �i�ڃR�[�h�Q
     ,iv_item_code_03       IN     VARCHAR2         -- 11 : �i�ڃR�[�h�R
     ,iv_item_code_04       IN     VARCHAR2         -- 12 : �i�ڃR�[�h�S
     ,iv_item_code_05       IN     VARCHAR2         -- 13 : �i�ڃR�[�h�T
     ,iv_vendor_id_01       IN     VARCHAR2         -- 14 : �����h�c�P
     ,iv_vendor_id_02       IN     VARCHAR2         -- 15 : �����h�c�Q
     ,iv_vendor_id_03       IN     VARCHAR2         -- 16 : �����h�c�R
     ,iv_vendor_id_04       IN     VARCHAR2         -- 17 : �����h�c�S
     ,iv_vendor_id_05       IN     VARCHAR2         -- 18 : �����h�c�T
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
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
    gr_param.output_type        := iv_output_type ;       -- �o�͌`��
    gr_param.fiscal_ym          := iv_fiscal_ym ;         -- �Ώ۔N��
    gr_param.prod_div           := iv_prod_div ;          -- ���i�敪
    gr_param.item_div           := iv_item_div ;          -- �i�ڋ敪
    gr_param.dept_code          := iv_dept_code ;         -- ��������
    gr_param.crowd_code_01      := iv_crowd_code_01 ;     -- �Q�R�[�h�P
    gr_param.crowd_code_02      := iv_crowd_code_02 ;     -- �Q�R�[�h�Q
    gr_param.crowd_code_03      := iv_crowd_code_03 ;     -- �Q�R�[�h�R
    gr_param.item_code_01       := iv_item_code_01 ;      -- �i�ڃR�[�h�P
    gr_param.item_code_02       := iv_item_code_02 ;      -- �i�ڃR�[�h�Q
    gr_param.item_code_03       := iv_item_code_03 ;      -- �i�ڃR�[�h�R
    gr_param.item_code_04       := iv_item_code_04 ;      -- �i�ڃR�[�h�S
    gr_param.item_code_05       := iv_item_code_05 ;      -- �i�ڃR�[�h�T
    gr_param.vendor_id_01       := iv_vendor_id_01 ;      -- �����h�c�P
    gr_param.vendor_id_02       := iv_vendor_id_02 ;      -- �����h�c�Q
    gr_param.vendor_id_03       := iv_vendor_id_03 ;      -- �����h�c�R
    gr_param.vendor_id_04       := iv_vendor_id_04 ;      -- �����h�c�S
    gr_param.vendor_id_05       := iv_vendor_id_05 ;      -- �����h�c�T
--
    -- =====================================================
    -- �O���[�o���ϐ��ҏW
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
    -- �p�����[�^���o��
    -- =====================================================
    prc_create_xml_data_param
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
    ------------------------------
    -- �����ʕ\�̏ꍇ
    ------------------------------
    IF ( gr_param.output_type IN( xxcmn820011c.program_id_01            -- ���ׁF����ʕi�ڕ�
                                 ,xxcmn820011c.program_id_02            -- ���v�F����ʕi�ڕ�
                                 ,xxcmn820011c.program_id_05            -- ���ׁF����ʎ�����
                                 ,xxcmn820011c.program_id_06 ) ) THEN   -- ���v�F����ʎ�����
--
      -- �������o�͏������Ăяo���B
      prc_create_xml_data_dpt
        (
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
    ------------------------------
    -- �i�ڕʎ����ʕ\�̏ꍇ
    ------------------------------
    ELSIF ( gr_param.output_type IN( xxcmn820011c.program_id_03                -- ���ׁF�i�ڕ�
                                    ,xxcmn820011c.program_id_04 ) ) THEN       -- ���v�F�i�ڕ�
--
      -- �i�ڏ��o�͏������Ăяo���B
      prc_create_xml_data_itm
        (
          iv_dept_code      => NULL
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
    ------------------------------
    -- �����ʕi�ڕʕ\�̏ꍇ
    ------------------------------
    ELSIF ( gr_param.output_type IN( xxcmn820011c.program_id_07             -- ���ׁF������
                                    ,xxcmn820011c.program_id_08 ) ) THEN    -- ���v�F������
--
      -- �������o�͏������Ăяo���B
      prc_create_xml_data_vnd
        (
          iv_dept_code      => NULL
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
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
    IF ( gb_get_flg = FALSE ) THEN
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
      -- ���ׁF����ʕi�ڕ�
      IF ( gr_param.output_type = xxcmn820011c.program_id_01 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_02 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_03 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_04 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_05 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_06 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_07 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_08 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      END IF ;
--
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
     ,iv_output_type        IN     VARCHAR2         -- 01 : �o�͌`��
     ,iv_fiscal_ym          IN     VARCHAR2         -- 02 : �Ώ۔N��
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 04 : �i�ڋ敪
     ,iv_dept_code          IN     VARCHAR2         -- 05 : ��������
     ,iv_crowd_code_01      IN     VARCHAR2         -- 06 : �Q�R�[�h�P
     ,iv_crowd_code_02      IN     VARCHAR2         -- 07 : �Q�R�[�h�Q
     ,iv_crowd_code_03      IN     VARCHAR2         -- 08 : �Q�R�[�h�R
     ,iv_item_code_01       IN     VARCHAR2         -- 09 : �i�ڃR�[�h�P
     ,iv_item_code_02       IN     VARCHAR2         -- 10 : �i�ڃR�[�h�Q
     ,iv_item_code_03       IN     VARCHAR2         -- 11 : �i�ڃR�[�h�R
     ,iv_item_code_04       IN     VARCHAR2         -- 12 : �i�ڃR�[�h�S
     ,iv_item_code_05       IN     VARCHAR2         -- 13 : �i�ڃR�[�h�T
     ,iv_vendor_id_01       IN     VARCHAR2         -- 14 : �����h�c�P
     ,iv_vendor_id_02       IN     VARCHAR2         -- 15 : �����h�c�Q
     ,iv_vendor_id_03       IN     VARCHAR2         -- 16 : �����h�c�R
     ,iv_vendor_id_04       IN     VARCHAR2         -- 17 : �����h�c�S
     ,iv_vendor_id_05       IN     VARCHAR2         -- 18 : �����h�c�T
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcmn820004c.main' ;  -- �v���O������
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
        iv_output_type    => iv_output_type           -- 01 : �o�͌`��
       ,iv_fiscal_ym      => iv_fiscal_ym             -- 02 : �Ώ۔N��
       ,iv_prod_div       => iv_prod_div              -- 03 : ���i�敪
       ,iv_item_div       => iv_item_div              -- 04 : �i�ڋ敪
       ,iv_dept_code      => iv_dept_code             -- 05 : ��������
       ,iv_crowd_code_01  => iv_crowd_code_01         -- 06 : �Q�R�[�h�P
       ,iv_crowd_code_02  => iv_crowd_code_02         -- 07 : �Q�R�[�h�Q
       ,iv_crowd_code_03  => iv_crowd_code_03         -- 08 : �Q�R�[�h�R
       ,iv_item_code_01   => iv_item_code_01          -- 09 : �i�ڃR�[�h�P
       ,iv_item_code_02   => iv_item_code_02          -- 10 : �i�ڃR�[�h�Q
       ,iv_item_code_03   => iv_item_code_03          -- 11 : �i�ڃR�[�h�R
       ,iv_item_code_04   => iv_item_code_04          -- 12 : �i�ڃR�[�h�S
       ,iv_item_code_05   => iv_item_code_05          -- 13 : �i�ڃR�[�h�T
       ,iv_vendor_id_01   => iv_vendor_id_01          -- 09 : �i�ڃR�[�h�P
       ,iv_vendor_id_02   => iv_vendor_id_02          -- 10 : �i�ڃR�[�h�Q
       ,iv_vendor_id_03   => iv_vendor_id_03          -- 11 : �i�ڃR�[�h�R
       ,iv_vendor_id_04   => iv_vendor_id_04          -- 12 : �i�ڃR�[�h�S
       ,iv_vendor_id_05   => iv_vendor_id_05          -- 13 : �i�ڃR�[�h�T
       ,ov_errbuf         => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn820021c ;
/
