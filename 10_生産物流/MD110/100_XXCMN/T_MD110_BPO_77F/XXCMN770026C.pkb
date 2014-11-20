CREATE OR REPLACE PACKAGE BODY xxcmn770026c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770026c(body)
 * Description      : �o�Ɏ��ѕ\
 * MD.050/070       : �����Y����(�o��)Issue1.0 (T_MD050_BPO_770)
 *                    �����Y����(�o��)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(F-1)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(F-1)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(F-2)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Y.Itou           �V�K�쐬
 *  2008/05/16    1.1   T.Endou          �s�ID:77F-09,10�Ή�
 *                                       77F-09 �����N���p��YYYYM���͑Ή�
 *                                       77F-10 �S�������A�S���Җ��̍ő啶���������̏C��
 *  2008/05/16    1.2   T.Endou          ���ی����擾���@�̕ύX
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
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCMN770026C' ; -- �p�b�P�[�W��
  gv_print_name               CONSTANT VARCHAR2(20) := '�o�Ɏ��ѕ\' ;   -- ���[��
--
  ------------------------------
  -- �W�v�O���[�v
  ------------------------------
  gc_party_sum_desc           CONSTANT VARCHAR2(16) := '�o�א�v';
  gc_whse_sum_desc            CONSTANT VARCHAR2(16) := '�q�Ɍv';
  gc_article_div_sum_name     CONSTANT VARCHAR2(16) := '�i�ڋ敪���v';
  gc_result_post_sum_name     CONSTANT VARCHAR2(16) := '���ѕ����v';
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_name_prod_div    CONSTANT VARCHAR2(20) := '���i�敪' ;
  gc_cat_set_name_item_div    CONSTANT VARCHAR2(20) := '�i�ڋ敪' ;
  gc_cat_set_name_crowd       CONSTANT VARCHAR2(20) := '�Q�R�[�h' ;
  gc_cat_set_name_acnt_crowd  CONSTANT VARCHAR2(20) := '�o�����p�Q�R�[�h' ;
--
  ------------------------------
  -- ���̓p�����[�^
  ------------------------------
  gc_param_all_code           CONSTANT VARCHAR2(20) := 'ALL' ;
  gc_param_all_name           CONSTANT VARCHAR2(20) := '�W�v����' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application              CONSTANT VARCHAR2(5)  := 'XXCMN' ;       -- �A�v���P�[�V����
  gc_crowd_type_3             CONSTANT VARCHAR2(1)  := '3' ;           -- �S��ʁF�S�R�[�h
  gc_crowd_type_4             CONSTANT VARCHAR2(1)  := '4' ;           -- �S��ʁF�o���S�R�[�h
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_ym_format           CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format            CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_dt_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  ------------------------------
  -- �N�C�b�N�R�[�h�E�^�C�v��
  ------------------------------
  gc_xxcmn_new_acc_div        CONSTANT VARCHAR2(30) := 'XXCMN_NEW_ACCOUNT_DIV';
--
  -- �����敪
  gc_cost_ac                  CONSTANT VARCHAR2(1) := '0'; --���ی���
  gc_cost_st                  CONSTANT VARCHAR2(1) := '1'; --�W������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
    proc_from                 VARCHAR2(6)       -- 01 : �����N��FROM
   ,proc_to                   VARCHAR2(6)       -- 02 : �����N��TO
   ,rcv_pay_div               VARCHAR2(5)       -- 03 : �󕥋敪
   ,rcv_pay_div_name          VARCHAR2(20)      --    : �󕥋敪��
   ,prod_div                  VARCHAR2(1)       -- 04 : ���i�敪
   ,prod_div_name             VARCHAR2(20)      --    : ���i�敪��
   ,item_div                  VARCHAR2(1)       -- 05 : �i�ڋ敪
   ,item_div_name             VARCHAR2(20)      --    : �i�ڋ敪��
   ,result_post               VARCHAR2(4)       -- 06 : ���ѕ���
   ,result_post_name          VARCHAR2(20)      --    : ���ѕ�����
   ,whse_code                 VARCHAR2(4)       -- 07 : �q�ɃR�[�h
   ,whse_name                 VARCHAR2(20)      --    : �q�ɖ�
   ,party_code                VARCHAR2(4)       -- 08 : �o�א�R�[�h
   ,party_name                VARCHAR2(20)      --    : �o�א於
   ,crowd_type                VARCHAR2(1)       -- 09 : �S���
   ,crowd_code                VARCHAR2(4)       -- 10 : �S�R�[�h
   ,acnt_crowd_code           VARCHAR2(4)       -- 11 : �o���Q�R�[�h
   ,output_type               VARCHAR2(20)      -- 12 : �o�͎��
  ) ;
--
  -- �o�׎��ѕ\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
    group1_code               VARCHAR2(5)                         -- [�W�v1]�R�[�h
   ,group2_code               VARCHAR2(5)                         -- [�W�v2]�R�[�h
   ,group3_code               VARCHAR2(5)                         -- [�W�v3]�R�[�h
   ,group4_code               VARCHAR2(5)                         -- [�W�v4]�R�[�h
   ,group5_code               VARCHAR2(4)                         -- [�W�v5]�W�v�S�R�[�h
   ,req_item_code             ic_item_mst_b.item_no%TYPE          -- �o�וi�ڃR�[�h
   ,item_code                 ic_item_mst_b.item_no%TYPE          -- �i�ڃR�[�h
   ,req_item_name             xxcmn_item_mst_b.item_name%TYPE     -- �o�וi�ږ���
   ,item_name                 xxcmn_item_mst_b.item_name%TYPE     -- �i�ږ���
   ,trans_um                  ic_tran_pnd.trans_um%TYPE           -- ����P��
   ,trans_qty                 NUMBER                              -- �������
   ,actual_price              NUMBER                              -- ���ۋ��z
   ,stnd_price                NUMBER                              -- �W�����z
   ,price                     NUMBER                              -- �L�����z
   ,tax                       NUMBER                              -- �����
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                    fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gv_user_dept                  xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name                  per_all_people_f.per_information18%TYPE;          -- �S����
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id                  VARCHAR2(12) ;              -- ���[ID
  gd_exec_date                  DATE ;                      -- ���{��
--
  gt_main_data                  tab_data_type_dtl ;         -- �擾���R�[�h�\
  gt_xml_data_table             XML_DATA ;                  -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                    NUMBER DEFAULT 0 ;          -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gv_gr1_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�P����
  gv_gr2_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�Q����
  gv_gr3_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�R����
  gv_gr4_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�S����
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
    iv_name              IN        VARCHAR2   --   �^�O�l�[��
   ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
   ,ic_type              IN        CHAR       --   �^�O�^�C�v
  ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
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
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(F-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
    ir_param             IN OUT NOCOPY rec_param_data -- 01.���̓p�����[�^�Q
   ,ov_errbuf               OUT    VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT    VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT    VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
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
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- ����敪���擾
    -- ====================================================
    -- �l�I���̏ꍇ�A���̂��擾����
    IF ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlvv.meaning, 1, 20)
        INTO   ir_param.rcv_pay_div_name
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type  = gc_xxcmn_new_acc_div
        AND    xlvv.lookup_code  = ir_param.rcv_pay_div
        AND    ROWNUM            = 1
        ;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- ���i�敪���擾
    -- ====================================================
    -- �l�I���̏ꍇ�A���̂��擾����
    IF ( ir_param.prod_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.prod_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_prod_div
        AND    xcv.segment1          = ir_param.prod_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- �i�ڋ敪���擾
    -- ====================================================
    -- �l�I���̏ꍇ�A���̂��擾����
    IF ( ir_param.item_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.item_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_item_div
        AND    xcv.segment1          = ir_param.item_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- ���ѕ������擾
    -- ====================================================
    -- [ALL]�̏ꍇ�A���̂ɌŒ�l�u�W�v�����v��ݒ�
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post = gc_param_all_code )
    THEN
      ir_param.result_post_name := gc_param_all_name;
--
    -- �l�I���̏ꍇ�A���̂��擾����
    ELSIF ( ir_param.result_post IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlv.location_short_name, 1, 20)
        INTO   ir_param.result_post_name
        FROM   xxcmn_locations_v xlv
        WHERE  xlv.location_code = ir_param.result_post
        AND    ROWNUM            = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- �q�ɖ��擾
    -- ====================================================
    -- [ALL]�̏ꍇ�A���̂ɌŒ�l�u�W�v�����v��ݒ�
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code = gc_param_all_code )
    THEN
      ir_param.whse_name := gc_param_all_name;
--
    -- �l�I���̏ꍇ�A���̂��擾����
    ELSIF ( ir_param.whse_code IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( iwm.whse_name, 1, 20)
        INTO   ir_param.whse_name
        FROM   ic_whse_mst iwm
        WHERE  iwm.whse_code = ir_param.whse_code
        AND    ROWNUM        = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- �o�א於�擾
    -- ====================================================
    -- [ALL]�̏ꍇ�A���̂ɌŒ�l�u�W�v�Ȃ��v��ݒ�
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code = gc_param_all_code )
    THEN
      ir_param.party_name := gc_param_all_name;
--
    -- �l�I���̏ꍇ�A���̂��擾����
    ELSIF ( ir_param.party_code IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xpv.party_short_name, 1, 20)
        INTO   ir_param.party_name
        FROM   xxcmn_parties_v xpv
        WHERE  xpv.party_number = ir_param.party_code
        AND    ROWNUM           = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
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
   * Description      : ���׃f�[�^�擾(F-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
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
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
--
    -- *** ���[�J���E�ϐ� ***
    lv_select               VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_omso            VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_porc            VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_where                VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_group_by             VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_order_by             VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql                  VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
--
    lv_crowd_c_name         VARCHAR2(20) ;        -- �S�R�[�h�J������(���o�����p)
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ----------------------------------------------------
    -- ��������
    -- ----------------------------------------------------
    -- �S�R�[�h�J�������ݒ�(3�F�S�R�[�h�^4�F�o���S�R�[�h)
    IF ( ir_param.crowd_type  = gc_crowd_type_3 ) THEN
      lv_crowd_c_name := 'crowd_code';
    ELSE
      lv_crowd_c_name := 'acnt_crowd_code';
    END IF;
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    lv_select := ' SELECT'
              || '  xrpm.request_item_code'     || ' AS request_item_code'  -- �o�וi�ڃR�[�h
              || ' ,ximv.item_short_name'       || ' AS request_item_name'  -- �o�וi�ږ���
              || ' ,xleiv.item_code'            || ' AS item_code'          -- �i�ڃR�[�h
              || ' ,xleiv.item_short_name'      || ' AS item_name'          -- �i�ږ���
              || ' ,itp.trans_um'               || ' AS trans_um'           -- ����P��
--
              || ' ,NVL2(xrpm.item_id, itp.trans_qty'
              ||                    ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
                                                || ' AS trans_qty'          -- �������
--
              || ' ,('
              || '   (CASE ximv.cost_manage_code'
                       -- �����Ǘ��敪=1:�W�� �W�������}�X�^�̎��ی���
              || '     WHEN ''' || gc_cost_st || ''' THEN xsupv.stnd_unit_price'
              || '     ELSE'
                       -- �����Ǘ��敪=0:����
                       -- ���b�g�Ǘ�=1:����   ���b�g�ʌ����e�[�u���̎��ی���
                       -- ���b�g�Ǘ�=0:���Ȃ� �W�������}�X�^�̎��ی���
              || '       DECODE(ximv.lot_ctl,1,'
              || '         (SELECT DECODE('
              || '            SUM(NVL(xlc.trans_qty,0)),0,0,'
              || '            SUM(xlc.trans_qty * xlc.unit_ploce)'
              || '              / SUM(NVL(xlc.trans_qty,0)))'
              || '          FROM  xxcmn_lot_cost xlc'
              || '          WHERE xlc.item_id = ximv.item_id )'
              || '       ,xsupv.stnd_unit_price)'
              || '    END)'
              || '     * NVL2(xrpm.item_id, itp.trans_qty'
              ||                         ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||  ' )'                          || ' AS actual_price'       -- ���ۋ��z
--
              || ' ,(xsupv.stnd_unit_price'
              ||     ' * NVL2(xrpm.item_id, itp.trans_qty'
              ||                         ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||  ' )'                          || ' AS stnd_price'         -- �W�����z
--
              || ' ,( CASE xleiv.lot_ctl'
              ||         ' WHEN  0 THEN ( xrpm.unit_price'
              ||                ' * NVL2(xrpm.item_id, itp.trans_qty'
              ||                                    ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||                       ' )'
              ||         ' ELSE'
              ||              ' ( '
              ||                 '(SELECT DECODE('
              ||                                ' SUM(NVL(xlc.trans_qty,0)),0,0,'
              ||                                ' SUM(xlc.trans_qty * xlc.unit_ploce)'
              ||                                 ' / SUM(NVL(xlc.trans_qty,0))'
              ||                              ' )'
              ||                ' FROM  xxcmn_lot_cost xlc'
              ||                ' WHERE xlc.item_id = itp.item_id )'
              ||                ' * NVL2(xrpm.item_id, itp.trans_qty'
              ||                                    ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||              ' )'
              ||     ' END )'                   || ' AS price'              -- �L�����z
              || ' ,xlvv2.lookup_code'          || ' AS tax'                -- ����ŗ�
              ;
--
    -- ----------------------------------------------------
    -- �W�v�p�^�[���ʂɂ��A�X�N���v�g����
    -- ----------------------------------------------------
    -- �W�v�p�^�[���P�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�q�ɁA4.�o�א�)
    IF  ( ir_param.result_post IS NULL )
    AND ( ir_param.whse_code   IS NULL )
    AND ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- ���ѕ���
                || ' ,xrpm.item_div'             || ' AS group2_code' -- �i�ڋ敪
                || ' ,itp.whse_code'             || ' AS group3_code' -- �q��
                || ' ,xpv.party_number'          || ' AS group4_code' -- �o�א�
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- ���ѕ����v
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr3_sum_desc := gc_whse_sum_desc;                            -- �q�Ɍv
      gv_gr4_sum_desc := gc_party_sum_desc;                           -- �o�א�v
--
    -- �W�v�p�^�[���Q�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�q��)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- ���ѕ���
                || ' ,xrpm.item_div'             || ' AS group2_code' -- �i�ڋ敪
                || ' ,itp.whse_code'             || ' AS group3_code' -- �q��
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- ���ѕ����v
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr3_sum_desc := gc_whse_sum_desc;                            -- �q�Ɍv
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- �W�v�p�^�[���R�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�o�א�)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- ���ѕ���
                || ' ,xrpm.item_div'             || ' AS group2_code' -- �i�ڋ敪
                || ' ,xpv.party_number'          || ' AS group3_code' -- �o�א�
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- ���ѕ����v
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr3_sum_desc := gc_party_sum_desc;                           -- �o�א�v
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
      -- �W�v�p�^�[���S�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- ���ѕ���
                || ' ,xrpm.item_div'             || ' AS group2_code' -- �i�ڋ敪
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- ���ѕ����v
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- �W�v�p�^�[���T�ݒ� (�W�v�F1.�i�ڋ敪�A2.�q�ɁA3.�o�א�)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- �i�ڋ敪
                || ' ,itp.whse_code'             || ' AS group2_code' -- �q��
                || ' ,xpv.party_number'          || ' AS group3_code' -- �o�א�
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr2_sum_desc := gc_whse_sum_desc;                            -- �q�Ɍv
      gv_gr3_sum_desc := gc_party_sum_desc;                           -- �o�א�v
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- �W�v�p�^�[���U�ݒ� (�W�v�F1.�i�ڋ敪�A2.�q��)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- �i�ڋ敪
                || ' ,itp.whse_code'             || ' AS group2_code' -- �q��
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr2_sum_desc := gc_whse_sum_desc;                            -- �q�Ɍv
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- �W�v�p�^�[���V�ݒ� (�W�v�F1.�i�ڋ敪�A2.�o�א�)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- �i�ڋ敪
                || ' ,xpv.party_number'          || ' AS group2_code' -- �o�א�
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h or �o���S�R�[�h
                ;
--
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr2_sum_desc := gc_party_sum_desc;                           -- �o�א�v
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- �W�v�p�^�[���W�ݒ� (�W�v�F1.�i�ڋ敪)
    ELSE
--
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- �i�ڋ敪
                || ' ,NULL'                      || ' AS group2_code' -- (NULL)
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- �S�R�[�h�^�o���S�R�[�h
                ;
      -- �W�v���̊i�[
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- �i�ڋ敪���v
      gv_gr2_sum_desc := NULL;                                        -- (NULL)
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
    END IF;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    -- ����VIEW(�w���֘A)��
    lv_from_porc := ' FROM'
                 ||       '  ic_tran_pnd'                  || ' itp'   -- �ۗ��݌Ƀg����
                 ||       ' ,xxcmn_rcv_pay_mst_porc_rma_v' || ' xrpm'  -- ��VIEW(�w���֘A)
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv'  -- �N�C�b�N�R�[�h
                 ||       ' ,xxcmn_lot_each_item_v'        || ' xleiv' -- ���b�g�ʕi�ڏ��
                 ||       ' ,xxcmn_stnd_unit_price_v'      || ' xsupv' -- �W���������View
                 ||       ' ,xxcmn_item_mst2_v'            || ' ximv'  -- OPM�i�ڏ��View2
                 ||       ' ,xxcmn_party_sites2_v'         || ' xpsv'  -- �p�[�e�B�T�C�g���View2
                 ||       ' ,xxcmn_parties2_v'             || ' xpv'   -- �p�[�e�B���View2
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv2' -- �N�C�b�N�R�[�h
                 ;
    -- ����VIEW(�󒍊֘A)��
    lv_from_omso := ' FROM'
                 ||       '  ic_tran_pnd'                  || ' itp'   -- �ۗ��݌Ƀg����
                 ||       ' ,xxcmn_rcv_pay_mst_omso_v'     || ' xrpm'  -- ��VIEW(�󒍊֘A)
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv'  -- �N�C�b�N�R�[�h
                 ||       ' ,xxcmn_lot_each_item_v'        || ' xleiv' -- ���b�g�ʕi�ڏ��
                 ||       ' ,xxcmn_stnd_unit_price_v'      || ' xsupv' -- �W���������View
                 ||       ' ,xxcmn_item_mst2_v'            || ' ximv'  -- OPM�i�ڏ��View2
                 ||       ' ,xxcmn_party_sites2_v'         || ' xpsv'  -- �p�[�e�B�T�C�g���View2
                 ||       ' ,xxcmn_parties2_v'             || ' xpv'   -- �p�[�e�B���View2
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv2' -- �N�C�b�N�R�[�h
                 ;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    -- ����VIEW(�w���֘A)��
    lv_from_porc := lv_from_porc
                 || ' WHERE'
                 ||           ' itp.doc_type'         || ' = ''PORC'''      -- �����^�C�v(PORC)
                 || ' AND' || ' itp.completed_ind'    || ' = 1'             -- �����t���O
                 || ' AND' || ' itp.doc_type'         || ' = xrpm.doc_type' -- �����^�C�v(PORC)
                 || ' AND' || ' itp.doc_id'           || ' = xrpm.doc_id'   -- ����ID
                 || ' AND' || ' itp.doc_line'         || ' = xrpm.doc_line' -- ������הԍ�
                 ;
    -- ����VIEW(�󒍊֘A)��
    lv_from_omso := lv_from_omso
                 || ' WHERE'
                 ||           ' itp.doc_type'         || ' = ''OMSO'''      -- �����^�C�v(OMSO)
                 || ' AND' || ' itp.completed_ind'    || ' = 1'             -- �����t���O
                 || ' AND' || ' itp.doc_type'         || ' = xrpm.doc_type' -- �����^�C�v(OMSO)
                 || ' AND' || ' itp.line_detail_id'   || ' = xrpm.doc_line' -- ������הԍ�
                 ;
--
    -- �u�����N��(��)�`(��)�v�𒊏o�����ɐݒ�
    lv_where := ' AND itp.trans_date >='
             ||     ' FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from || ''',''yyyymm'')'
             || ' AND itp.trans_date < '
             ||     ' ADD_MONTHS( FND_DATE.STRING_TO_DATE('''
             ||                                      ir_param.proc_to || ''',''yyyymm''),1)'
             ;
--
    -- �u�󕥋敪�v�𒊏o�����ɐݒ�
    IF  ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      lv_where := lv_where
               || ' AND xrpm.new_div_account = ''' || ir_param.rcv_pay_div || ''''
               ;
    END IF;
--
    -- �u�q�ɃR�[�h�v���ʑI������Ă���ꍇ(*ALL������)�A���o�����ɐݒ�
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code != gc_param_all_code )
    THEN
      lv_where := lv_where
               || ' AND itp.whse_code = '''        || ir_param.whse_code || ''''
               ;
    END IF;
--
    -- �u���ѕ����v���ʑI������Ă���ꍇ(*ALL������)�A���o�����ɐݒ�
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post != gc_param_all_code )
    THEN
      lv_where := lv_where
               || ' AND xrpm.result_post = '''     || ir_param.result_post || ''''
               ;
    END IF;
--
    -- �N�C�b�N�R�[�h(xxcmn_lookup_values2_v)�A��
    lv_where := lv_where
             || ' AND' || ' xlvv.lookup_type'   || ' = ''XXCMN_MONTH_TRANS_OUTPUT_FLAG'''
             || ' AND' || ' xrpm.dealings_div'  || ' = xlvv.meaning'
             || ' AND' || ' (xlvv.start_date_active IS NULL'
             ||           ' OR xlvv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xlvv.end_date_active IS NULL'
             ||           ' OR xlvv.end_date_active >= TRUNC(itp.trans_date) )'
             || ' AND' || ' xlvv.language'      || ' = ''JA'''
             || ' AND' || ' xlvv.source_lang'   || ' = ''JA'''
             || ' AND' || ' xlvv.attribute6'    || ' IS NOT NULL'
             ;
--
    -- ���b�g�ʕi�ڏ��(xxcmn_lot_each_item_v)�A��
    lv_where := lv_where
             || ' AND' || ' itp.item_id'        || ' = xleiv.item_id'        -- �i��ID
             || ' AND' || ' itp.lot_id'         || ' = xleiv.lot_id'         -- ���b�gID
             || ' AND' || ' (xleiv.start_date_active IS NULL'
             ||           ' OR xleiv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xleiv.end_date_active IS NULL'
             ||           ' OR xleiv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- �u�S��ʁv���u3:�S�R�[�h�v�ŁA���A�u�S�R�[�h�v�����͂���Ă���ꍇ�A���o�����ɐݒ�
    IF    ( ir_param.crowd_type = gc_crowd_type_3 )
    AND   ( ir_param.crowd_code IS NOT NULL )
    THEN
      lv_where := lv_where
               || ' AND xrpm.crowd_code = '''      || ir_param.crowd_code || ''''
               ;
    -- �u�S��ʁv���u4:�o���S�R�[�h�v�ŁA���A�u�o���S�R�[�h�v�����͂���Ă���ꍇ�A���o�����ɐݒ�
    ELSIF ( ir_param.crowd_type =  '4' )
    AND   ( ir_param.acnt_crowd_code IS NOT NULL )
    THEN
      lv_where := lv_where
               || ' AND xrpm.acnt_crowd_code = ''' || ir_param.acnt_crowd_code || ''''
               ;
    END IF;
--
    -- �u�i�ڋ敪�v���ʑI������Ă���ꍇ�A���o�����ɐݒ�
    IF  ( ir_param.item_div IS NOT NULL ) THEN
      lv_where := lv_where
               || ' AND xrpm.item_div = '''        || ir_param.item_div || ''''
               ;
    END IF;
--
    -- �u���i�敪�v���ʑI������Ă���ꍇ�A���o�����ɐݒ�
    IF  ( ir_param.prod_div IS NOT NULL ) THEN
      lv_where := lv_where
               || ' AND xrpm.prod_div = '''        || ir_param.prod_div || ''''
               ;
    END IF;
--
    -- �W���������View(xxcmn_stnd_unit_price_v)�A��
    lv_where := lv_where
             || ' AND' || ' NVL(xrpm.item_id, itp.item_id)' || ' = xsupv.item_id' -- �i��ID
             || ' AND' || ' (xsupv.start_date_active IS NULL'
             ||           ' OR xsupv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xsupv.end_date_active IS NULL'
             ||           ' OR xsupv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- OPM�i�ڏ��View2(xxcmn_item_mst2_v)�A��
    lv_where := lv_where
             || ' AND' || ' xrpm.request_item_code' || ' = ximv.item_no(+)'     -- ���i�󕥕i��ID
             || ' AND' || ' (ximv.start_date_active IS NULL'
             ||           ' OR ximv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (ximv.end_date_active IS NULL'
             ||           ' OR ximv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- �p�[�e�B�T�C�g���View2(xxcmn_party_sites2_v)�A��
    lv_where := lv_where
             || ' AND' || ' xrpm.deliver_to_id'   || ' = xpsv.party_site_id'    -- �o�א�ID
             || ' AND' || ' (xpsv.start_date_active IS NULL'
             ||           ' OR xpsv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xpsv.end_date_active IS NULL'
             ||           ' OR xpsv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- �u�o�א�R�[�h�v���ʑI������Ă���ꍇ(*ALL������)�A���o�����ɐݒ�
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code != gc_param_all_code )
    THEN
      lv_where := lv_where
               || ' AND xpv.party_number = '''    || ir_param.party_code || ''''
               ;
    END IF;
--
    -- �p�[�e�B���View2(xxcmn_parties2_v)�A��
    lv_where := lv_where
             || ' AND' || ' xpsv.party_id'        || ' = xpv.party_id'          -- �p�[�e�BID
             || ' AND' || ' (xpv.start_date_active IS NULL'
             ||           ' OR xpv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xpv.end_date_active IS NULL'
             ||           ' OR xpv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- �N�C�b�N�R�[�h(xxcmn_lookup_values2_v)�A���|����ŗ�
    lv_where := lv_where
             || ' AND' || ' xlvv2.lookup_type'    || ' = ''XXCMN_CONSUMPTION_TAX_RATE'''
             || ' AND' || ' (xlvv2.start_date_active IS NULL'
             ||           ' OR xlvv2.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xlvv2.end_date_active IS NULL'
             ||           ' OR xlvv2.end_date_active >= TRUNC(itp.trans_date) )'
             || ' AND' || ' xlvv2.language'       || ' = ''JA'''
             || ' AND' || ' xlvv2.source_lang'    || ' = ''JA'''
             ;
--
    -- ----------------------------------------------------
    -- �f�q�n�t�o �a�x�吶��
    -- ----------------------------------------------------
    lv_group_by := ' GROUP BY'
                || '  mst.group1_code'           -- [�W�v1]�R�[�h
                || ' ,mst.group2_code'           -- [�W�v2]�R�[�h
                || ' ,mst.group3_code'           -- [�W�v3]�R�[�h
                || ' ,mst.group4_code'           -- [�W�v4]�R�[�h
                || ' ,mst.group5_code'           -- [�W�v5]�R�[�h
                || ' ,mst.request_item_code'     -- �o�וi�ڃR�[�h
                || ' ,mst.item_code'             -- �i�ڃR�[�h
                ;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q �a�x�吶��
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || '  mst.group1_code'           -- [�W�v1]�R�[�h
                || ' ,mst.group2_code'           -- [�W�v2]�R�[�h
                || ' ,mst.group3_code'           -- [�W�v3]�R�[�h
                || ' ,mst.group4_code'           -- [�W�v4]�R�[�h
                || ' ,mst.group5_code'           -- [�W�v5]�R�[�h
                || ' ,mst.request_item_code'     -- �o�וi�ڃR�[�h
                || ' ,mst.item_code'             -- �i�ڃR�[�h
                ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := 'SELECT'
           ||       ' mst.group1_code'            || ' AS group1_code'        -- [�W�v1]�R�[�h
           ||       ',mst.group2_code'            || ' AS group2_code'        -- [�W�v2]�R�[�h
           ||       ',mst.group3_code'            || ' AS group3_code'        -- [�W�v3]�R�[�h
           ||       ',mst.group4_code'            || ' AS group4_code'        -- [�W�v4]�R�[�h
           ||       ',mst.group5_code'            || ' AS group5_code'        -- [�W�v5]�R�[�h
           ||       ',mst.request_item_code'      || ' AS request_item_code'  -- �o�וi�ڃR�[�h
           ||       ',mst.item_code'              || ' AS item_code'          -- �i�ڃR�[�h
           ||       ',MAX(mst.request_item_name)' || ' AS request_item_name'  -- �o�וi�ږ���
           ||       ',MAX(mst.item_name)'         || ' AS item_name'          -- ����P��
           ||       ',MAX(mst.trans_um)'          || ' AS trans_um'           -- �������
           ||       ',SUM(mst.trans_qty)'         || ' AS trans_qty'          -- �������
           ||       ',SUM(mst.actual_price)'      || ' AS actual_price'       -- ���ۋ��z
           ||       ',SUM(mst.stnd_price)'        || ' AS stnd_price'         -- �W�����z
           ||       ',SUM(mst.price)'             || ' AS price'              -- �L�����z
           ||       ',SUM(mst.price * DECODE( NVL(mst.tax,0),0,0,(mst.tax/100) ) )'
           ||                                        ' AS tax'                -- ����ŗ�
           || ' FROM ('
--
           -- ����VIEW(�w���֘A)��
           || lv_select || lv_from_porc || lv_where
--
           || ' UNION ALL '
--
           -- ����VIEW(�󒍊֘A)��
             || lv_select || lv_from_omso || lv_where
--
           || ' ) mst'
           || lv_group_by
           || lv_order_by
           ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
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
   * Description      : �w�l�k�f�[�^�쐬(F-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
    ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
   ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �L�[�u���C�N���f�p
    lc_break_init         VARCHAR2(100) DEFAULT '#' ;            -- �����l
    lc_break_null         VARCHAR2(100) DEFAULT '*' ;            -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_gp_cd1             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�P
    lv_gp_cd2             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�Q
    lv_gp_cd3             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�R
    lv_gp_cd4             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�S
    lv_crowd_l            VARCHAR2(1)   DEFAULT lc_break_init ;              -- ��S�v�O���[�v
    lv_crowd_m            VARCHAR2(2)   DEFAULT lc_break_init ;              -- ���S�v�O���[�v
    lv_crowd_s            VARCHAR2(3)   DEFAULT lc_break_init ;              -- ���S�v�O���[�v
    lv_crowd_cd           VARCHAR2(4)   DEFAULT lc_break_init ;              -- �ڌS�v�O���[�v
--
    -- �v�Z�p
    ln_position           NUMBER        DEFAULT 0;               -- �v�Z�p�F�|�W�V����
    ln_i                  NUMBER        DEFAULT 0;               -- �J�E���^�[�p
    lv_trans_qty          NUMBER ;                               -- �������
    lv_tax                NUMBER ;                               -- ����ŗ�
    lv_tax_price          NUMBER ;                               -- �����
    ln_unit_price1        NUMBER ;                               -- �W������
    ln_unit_price2        NUMBER ;                               -- �L������
    ln_unit_price3        NUMBER ;                               -- ���ےP��
    ln_unit_price4        NUMBER ;                               -- �L�|�W�i�����j
    ln_unit_price5        NUMBER ;                               -- �L�|���i�����j
    ln_unit_price6        NUMBER ;                               -- �W�|���i�����j
    lv_price1             NUMBER ;                               -- �W�����z
    lv_price2             NUMBER ;                               -- �L�����z
    lv_price3             NUMBER ;                               -- ���ۋ��z
    lv_price4             NUMBER ;                               -- �L�|�W�i���z�j
    lv_price5             NUMBER ;                               -- �L�|���i���z�j
    lv_price6             NUMBER ;                               -- �W�|���i���z�j
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
    -- *** ���[�J���֐� ***
    ----------------------
    --1.�w�l�k 1�s�o��   -
    ----------------------
    PROCEDURE prc_xml_add(
       iv_name    IN   VARCHAR2                 --   �^�O�l�[��
      ,ic_type    IN   CHAR                     --   �^�O�^�C�v
      ,iv_data    IN   VARCHAR2 DEFAULT NULL)   --   �f�[�^
    IS
    BEGIN
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := iv_name;
      --�f�[�^�̏ꍇ
      IF (ic_type = 'D') THEN
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := iv_data;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
    END prc_xml_add;
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
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���w�b�_�������ڃf�[�^���o�E�o�͏���
    -- =====================================================
--
    -- -----------------------------------------------------
    -- [USER_INFO] �f�[�^�o��
    -- -----------------------------------------------------
    prc_xml_add('user_info', 'T', NULL);
--
    prc_xml_add('exec_date',          'D', TO_CHAR(gd_exec_date, gc_char_dt_format) ); -- ���{��
    prc_xml_add('report_id',          'D', gv_report_id);                    -- ���[�h�c
    prc_xml_add('exec_user_dept',     'D', SUBSTRB(gv_user_dept,1,10) );     -- �S������
    prc_xml_add('exec_user_name',     'D', SUBSTRB(gv_user_name,1,14) );     -- �S���Җ�
    -- �p�����[�^
    prc_xml_add('p_item_div_code',    'D', ir_param.prod_div );              -- ���i�敪
    prc_xml_add('p_item_div_name',    'D', ir_param.prod_div_name );         -- ���i�敪��
    prc_xml_add('p_party_code',       'D', ir_param.party_code );            -- �o�א�R�[�h
    prc_xml_add('p_party_name',       'D', ir_param.party_name );            -- �o�א於
    prc_xml_add('p_locat_code',       'D', ir_param.whse_code );             -- �q�ɃR�[�h
    prc_xml_add('p_locat_name',       'D', ir_param.whse_name );             -- �q�ɖ�
    prc_xml_add('p_rcv_pay_div_code', 'D', ir_param.rcv_pay_div );           -- �󕥋敪
    prc_xml_add('p_rcv_pay_div_name', 'D', ir_param.rcv_pay_div_name );      -- �󕥋敪��
    prc_xml_add('p_article_div_code', 'D', ir_param.item_div );              -- �i�ڋ敪
    prc_xml_add('p_article_div_name', 'D', ir_param.item_div_name );         -- �i�ڋ敪��
    prc_xml_add('p_result_post_code', 'D', ir_param.result_post );           -- ���ѕ���
    prc_xml_add('p_result_post_name', 'D', ir_param.result_post_name );      -- ���ѕ�����
    -- �����N��(��)
    prc_xml_add('p_trans_ym_from','D', SUBSTRB(ir_param.proc_from,1,4) || '�N'
                                    || SUBSTRB(ir_param.proc_from,5,2) || '��' );
    -- �����N��(��)
    prc_xml_add('p_trans_ym_to',  'D', SUBSTRB(ir_param.proc_to,1,4) || '�N'
                                    || SUBSTRB(ir_param.proc_to,5,2) || '��' );
--
    prc_xml_add('/user_info', 'T', NULL);
--
    -- =====================================================
    -- �����ו������ڃf�[�^���o�E�o�͏���
    -- =====================================================
    ln_i := 1;
    -- -----------------------------------------------------
    -- [DATA_INFO] �J�n�^�O�o��
    -- -----------------------------------------------------
    prc_xml_add('data_info', 'T');
    prc_xml_add('lg_gr1',    'T');
--
    --=============================================�W�v�P���[�v�J�n
    <<group1_loop>>
    WHILE ( ln_i  <= gt_main_data.COUNT )
    LOOP
      prc_xml_add('g_gr1', 'T');
      prc_xml_add('gr1_code',     'D', gt_main_data(ln_i).group1_code);
      prc_xml_add('gr1_sum_desc', 'D', gv_gr1_sum_desc);
      lv_gp_cd1  :=  NVL(gt_main_data(ln_i).group1_code, lc_break_null);
      --=============================================�W�v�Q���[�v�J�n
      prc_xml_add('lg_gr2', 'T');
      <<group2_loop>>
      WHILE ( ln_i  <= gt_main_data.COUNT )
        AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
      LOOP
        prc_xml_add('g_gr2', 'T');
        prc_xml_add('gr2_code',     'D', gt_main_data(ln_i).group2_code);
        prc_xml_add('gr2_sum_desc', 'D', gv_gr2_sum_desc);
        lv_gp_cd2  :=  NVL(gt_main_data(ln_i).group2_code, lc_break_null);
        --===============================================�W�v�R���[�v�J�n
        prc_xml_add('lg_gr3', 'T');
        <<group3_loop>>
        WHILE ( ln_i  <= gt_main_data.COUNT )
          AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
          AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
        LOOP
          prc_xml_add('g_gr3', 'T');
          prc_xml_add('gr3_code',     'D', gt_main_data(ln_i).group3_code);
          prc_xml_add('gr3_sum_desc', 'D', gv_gr3_sum_desc);
          lv_gp_cd3  :=  NVL(gt_main_data(ln_i).group3_code, lc_break_null);
          --================================================�W�v�S���[�v�J�n
          prc_xml_add('lg_gr4', 'T');
          <<group4_loop>>
          WHILE ( ln_i  <= gt_main_data.COUNT )
            AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
            AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
            AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
          LOOP
            prc_xml_add('g_gr4', 'T');
            prc_xml_add('gr4_code',     'D', gt_main_data(ln_i).group4_code);
            prc_xml_add('gr4_sum_desc', 'D', gv_gr4_sum_desc);
            lv_gp_cd4  :=  NVL(gt_main_data(ln_i).group4_code, lc_break_null);
            --================================================��S�v���[�v�J�n
            prc_xml_add('lg_crowd_l', 'T');
            <<crowd_l_loop>>
            WHILE ( ln_i  <= gt_main_data.COUNT )
              AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
              AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
              AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
              AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
            LOOP
              prc_xml_add('g_crowd_l', 'T');
              prc_xml_add('crowd_lcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,1) );
              lv_crowd_l  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1), lc_break_null);
              --================================================���S�v���[�v�J�n
              prc_xml_add('lg_crowd_m', 'T');
              <<crowd_m_loop>>
              WHILE ( ln_i  <= gt_main_data.COUNT )
                AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1),lc_break_null)= lv_crowd_l)
              LOOP
                prc_xml_add('g_crowd_m', 'T');
                prc_xml_add('crowd_mcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,2) );
                lv_crowd_m  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2), lc_break_null);
                --================================================���S�v���[�v�J�n
                prc_xml_add('lg_crowd_s', 'T');
                <<crowd_s_loop>>
                WHILE ( ln_i  <= gt_main_data.COUNT )
                  AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                  AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                  AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                  AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                  AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2),lc_break_null)
                                                                           = lv_crowd_m)
                LOOP
                  prc_xml_add('g_crowd_s', 'T');
                  prc_xml_add('crowd_scode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,3) );
                  lv_crowd_s := NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3), lc_break_null);
                  --================================================�ڌS�v���[�v�J�n
                  prc_xml_add('lg_crowd', 'T');
                  <<crowd_loop>>
                  WHILE ( ln_i  <= gt_main_data.COUNT )
                    AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                    AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                    AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                    AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                    AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3),lc_break_null)
                                                                             = lv_crowd_s)
                  LOOP
                    prc_xml_add('g_crowd', 'T');
                    prc_xml_add('crowd_code', 'D', gt_main_data(ln_i).group5_code );
                    --================================================�i�ڃ��[�v�J�n
                    lv_crowd_cd := NVL(gt_main_data(ln_i).group5_code, lc_break_null);
                    prc_xml_add('lg_item', 'T');
                    <<item_loop>>
                    WHILE ( ln_i  <= gt_main_data.COUNT )
                      AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                      AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                      AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                      AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                      AND ( NVL(gt_main_data(ln_i).group5_code, lc_break_null) = lv_crowd_cd)
                    LOOP
                      prc_xml_add('g_item', 'T');
--
                      -- -----------------------------------------------------
                      -- ������
                      -- -----------------------------------------------------
                      lv_trans_qty   := NULL;    -- �������
                      lv_tax         := NULL;    -- ����ŗ�
                      lv_tax_price   := NULL;    -- �����
                      ln_unit_price1 := NULL;    -- �W������
                      ln_unit_price2 := NULL;    -- �L������
                      ln_unit_price3 := NULL;    -- ���ےP��
                      ln_unit_price4 := NULL;    -- �L�|�W�i�����j
                      ln_unit_price5 := NULL;    -- �L�|���i�����j
                      ln_unit_price6 := NULL;    -- �W�|���i�����j
                      lv_price1      := NULL;    -- �W�����z
                      lv_price2      := NULL;    -- �L�����z
                      lv_price3      := NULL;    -- ���ۋ��z
                      lv_price4      := NULL;    -- �L�|�W�i���z�j
                      lv_price5      := NULL;    -- �L�|���i���z�j
                      lv_price6      := NULL;    -- �W�|���i���z�j
--
                      -- -----------------------------------------------------
                      -- �Z�o�����{�܂�ߏ���
                      -- -----------------------------------------------------
                      -- ����
                      IF  ( NVL(gt_main_data(ln_i).trans_qty,0) != 0 ) THEN
                        lv_trans_qty     := ROUND(gt_main_data(ln_i).trans_qty, 3);
                      END IF;
                      -- �W�����z
                      IF  ( NVL(gt_main_data(ln_i).stnd_price,0) != 0 ) THEN
                        lv_price1        := ROUND(gt_main_data(ln_i).stnd_price);
                        -- �W������
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price1 := ROUND(gt_main_data(ln_i).stnd_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- �L�����z
                      IF  ( NVL(gt_main_data(ln_i).price,0) != 0 ) THEN
                        lv_price2        := ROUND(gt_main_data(ln_i).price);
                        -- �L���P��
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price2 := ROUND(gt_main_data(ln_i).price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- �����
                      IF  ( NVL(gt_main_data(ln_i).tax,0) != 0 ) THEN
                        lv_tax_price     := ROUND(gt_main_data(ln_i).tax);
                      END IF;
                      -- ���ۋ��z
                      IF  ( NVL(gt_main_data(ln_i).actual_price,0) != 0 ) THEN
                        lv_price3        := ROUND(gt_main_data(ln_i).actual_price);
                        -- ���ی���
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price3 := ROUND(gt_main_data(ln_i).actual_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- �L�|�W(�P��)
                      ln_unit_price4   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price1,0), 2);
                      -- �L�|�W(���z)
                      lv_price4        := ROUND( NVL(lv_price2,0)      - NVL(lv_price1,0) );
                      -- �L�|��(�P��)
                      ln_unit_price5   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price3,0), 2);
                      -- �L�|��(���z)
                      lv_price5        := ROUND( NVL(lv_price2,0)      - NVL(lv_price3,0) );
                      -- �W�|��(�P��)
                      ln_unit_price6   := ROUND( NVL(ln_unit_price1,0) - NVL(ln_unit_price3,0), 2);
                      -- �W�|��(���z)
                      lv_price6        := ROUND( NVL(lv_price1,0)      - NVL(lv_price3,0) );
--
                      -- -----------------------------------------------------
                      -- XML�o��
                      -- -----------------------------------------------------
                      -- �o�וi�ڃR�[�h�E�o�וi�ږ���
                      prc_xml_add('req_item_code','D', gt_main_data(ln_i).req_item_code );
                      prc_xml_add('req_item_name','D', gt_main_data(ln_i).req_item_name );
                      -- �i�ڃR�[�h�E�i�ږ���
                      prc_xml_add('item_code'    ,'D', gt_main_data(ln_i).item_code );
                      prc_xml_add('item_name'    ,'D', gt_main_data(ln_i).item_name );
                      -- �P��
                      prc_xml_add('item_um'      ,'D', gt_main_data(ln_i).trans_um );
                      -- ����
                      IF ( lv_trans_qty IS NOT NULL ) THEN
                        prc_xml_add('trans_qty'  ,'D', lv_trans_qty );
                      END IF;
                      -- �����
                      IF ( lv_tax_price IS NOT NULL ) THEN
                        prc_xml_add('tax_price'  ,'D', lv_tax_price );
                      END IF;
                      -- �W������
                      IF ( ln_unit_price1 IS NOT NULL ) THEN
                        prc_xml_add('unit_price1','D', ln_unit_price1 );
                      END IF;
                      -- �W�����z
                      IF ( lv_price1 IS NOT NULL ) THEN
                        prc_xml_add('price1'     ,'D', lv_price1 );
                      END IF;
                      -- �L���P��
                      IF ( ln_unit_price2 IS NOT NULL ) THEN
                        prc_xml_add('unit_price2','D', ln_unit_price2 );
                      END IF;
                      -- �L�����z
                      IF ( lv_price2 IS NOT NULL ) THEN
                        prc_xml_add('price2'     ,'D', lv_price2 );
                      END IF;
                      -- ���ی���
                      IF ( ln_unit_price3 IS NOT NULL ) THEN
                        prc_xml_add('unit_price3','D', ln_unit_price3 );
                      END IF;
                      -- ���ۋ��z
                      IF ( lv_price3 IS NOT NULL ) THEN
                        prc_xml_add('price3'     ,'D', lv_price3 );
                      END IF;
                      -- �L�|�W�i�����j
                      IF ( ln_unit_price4 IS NOT NULL ) THEN
                        prc_xml_add('unit_price4','D', ln_unit_price4 );
                      END IF;
                      -- �L�|�W�i���z�j
                      IF ( lv_price4 IS NOT NULL ) THEN
                        prc_xml_add('price4'     ,'D', lv_price4 );
                      END IF;
                      -- �L�|���i�����j
                      IF ( ln_unit_price5 IS NOT NULL ) THEN
                        prc_xml_add('unit_price5','D', ln_unit_price5 );
                      END IF;
                      -- �L�|���i���z�j
                      IF ( lv_price5 IS NOT NULL ) THEN
                        prc_xml_add('price5'     ,'D', lv_price5 );
                      END IF;
                      -- �W�|���i�P���j
                      IF ( ln_unit_price6 IS NOT NULL ) THEN
                        prc_xml_add('unit_price6','D', ln_unit_price6 );
                      END IF;
                      -- �W�|���i���z�j
                      IF ( lv_price6 IS NOT NULL ) THEN
                        prc_xml_add('price6'     ,'D', lv_price6 );
                      END IF;
--
                      ln_i  :=  ln_i  + 1; --�����׈ʒu
                      prc_xml_add('/g_item', 'T');
                    END LOOP  item_loop;
                    prc_xml_add('/lg_item', 'T');
                    --================================================�ڌS�v���[�v�I��
                    prc_xml_add('/g_crowd', 'T');
                  END LOOP  crowd_loop;
                  prc_xml_add('/lg_crowd', 'T');
                  --================================================�ڌS�v���[�v�I��
                  prc_xml_add('/g_crowd_s', 'T');
                END LOOP  crowd_s_loop;
                prc_xml_add('/lg_crowd_s', 'T');
                --================================================���S�v���[�v�I��
                prc_xml_add('/g_crowd_m', 'T');
              END LOOP  crowd_m_loop;
              prc_xml_add('/lg_crowd_m', 'T');
              --================================================���S�v���[�v�I��
              prc_xml_add('/g_crowd_l', 'T');
            END LOOP  crowd_l_loop;
            prc_xml_add('/lg_crowd_l', 'T');
          --================================================��S�v���[�v�I��
          prc_xml_add('/g_gr4', 'T');
          END LOOP  group4_loop;
          prc_xml_add('/lg_gr4', 'T');
          --================================================�W�v�S���[�v�I��
          prc_xml_add('/g_gr3', 'T');
        END LOOP  group3_loop;
        prc_xml_add('/lg_gr3', 'T');
        --================================================�W�v�R���[�v�I��
        prc_xml_add('/g_gr2', 'T');
      END LOOP  group2_loop;
      prc_xml_add('/lg_gr2', 'T');
      --================================================�W�v�Q���[�v�I��
      --�ŏI���R�[�h�̏ꍇ�A�����v�s�o�̓t���O��ON�ɂ���B
      IF (ln_i > gt_main_data.COUNT) THEN
        prc_xml_add('last_recode_flg', 'D', 'Y');
      ELSE
        prc_xml_add('last_recode_flg', 'D', 'N');
      END IF;
      prc_xml_add('/g_gr1', 'T');
    END LOOP  group1_loop;
    prc_xml_add('/lg_gr1', 'T');
    --================================================�W�v�P���[�v�I��
--
    prc_xml_add('/data_info', 'T'); --�f�[�^�I��
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' ) ;
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
  PROCEDURE submain (
    iv_proc_from          IN    VARCHAR2  --   01 : �����N��FROM
   ,iv_proc_to            IN    VARCHAR2  --   02 : �����N��TO
   ,iv_rcv_pay_div        IN    VARCHAR2  --   03 : �󕥋敪
   ,iv_prod_div           IN    VARCHAR2  --   04 : ���i�敪
   ,iv_item_div           IN    VARCHAR2  --   05 : �i�ڋ敪
   ,iv_result_post        IN    VARCHAR2  --   06 : ���ѕ���
   ,iv_whse_code          IN    VARCHAR2  --   07 : �q�ɃR�[�h
   ,iv_party_code         IN    VARCHAR2  --   08 : �o�א�R�[�h
   ,iv_crowd_type         IN    VARCHAR2  --   09 : �S���
   ,iv_crowd_code         IN    VARCHAR2  --   10 : �S�R�[�h
   ,iv_acnt_crowd_code    IN    VARCHAR2  --   11 : �o���Q�R�[�h
   ,iv_output_type        IN    VARCHAR2  --   12 : �o�͎��
   ,ov_errbuf            OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
    lv_work_date            VARCHAR2(30); -- �ϊ��p
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
    gv_report_id                 := iv_output_type || 'T' ;-- ���[ID
    gd_exec_date                 := SYSDATE ;              -- ���{��
    -- �p�����[�^�i�[
    -- �����N��FROM
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_from, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_from     := iv_proc_from;
    ELSE
      lr_param_rec.proc_from     := lv_work_date;
    END IF;
    -- �����N��TO
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_to, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_to     := iv_proc_to;
    ELSE
      lr_param_rec.proc_to     := lv_work_date;
    END IF;
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;        -- �󕥋敪
    lr_param_rec.prod_div        := iv_prod_div;           -- ���i�敪
    lr_param_rec.item_div        := iv_item_div;           -- �i�ڋ敪
    lr_param_rec.result_post     := iv_result_post;        -- ���ѕ���
    lr_param_rec.whse_code       := iv_whse_code;          -- �q�ɃR�[�h
    lr_param_rec.party_code      := iv_party_code;         -- �o�א�R�[�h
    lr_param_rec.crowd_type      := iv_crowd_type;         -- �S���
    lr_param_rec.crowd_code      := iv_crowd_code;         -- �S�R�[�h
    lr_param_rec.acnt_crowd_code := iv_acnt_crowd_code;    -- �o���Q�R�[�h
    lr_param_rec.output_type     := iv_output_type;        -- �o�͎��
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>') ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <user_info>') ;
      -- �w�l�k�^�O�o�� �� ���{��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_date>'
                                       ||    TO_CHAR(gd_exec_date, gc_char_dt_format)
                                       || '</exec_date>'
                       );
      -- �w�l�k�^�O�o�� �� ���[�h�c
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<report_id>'
                                       ||    gv_report_id
                                       || '</report_id>'
                       );
      -- �w�l�k�^�O�o�� �� �S������
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_dept>'
                                       ||    SUBSTRB(gv_user_dept,1,20)
                                       || '</exec_user_dept>'
                       );
      -- �w�l�k�^�O�o�� �� �S���Җ�
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_name>'
                                       ||    SUBSTRB(gv_user_name,1,20)
                                       || '</exec_user_name>'
                       );
      -- �w�l�k�^�O�o�́F���i�敪
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_code>'
                                       ||    lr_param_rec.prod_div
                                       || '</p_item_div_code>'
                       );
      -- �w�l�k�^�O�o�́F���i�敪��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_name>'
                                       ||    lr_param_rec.prod_div_name
                                       || '</p_item_div_name>'
                       );
      -- �w�l�k�^�O�o�� �o�א�R�[�h
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_code>'
                                       ||    lr_param_rec.party_code
                                       || '</p_party_code>'
                       );
      -- �w�l�k�^�O�o�� �o�א於
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_name>'
                                       ||    lr_param_rec.party_name
                                       || '</p_party_name>'
                       );
      -- �w�l�k�^�O�o�� �q�ɃR�[�h
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_code>'
                                       ||    lr_param_rec.whse_code
                                       || '</p_locat_code>'
                       );
      -- �w�l�k�^�O�o�� �q�ɖ�
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_name>'
                                       ||    lr_param_rec.whse_name
                                       || '</p_locat_name>'
                       );
      -- �w�l�k�^�O�o�� �� �󕥋敪
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_code>'
                                       ||    lr_param_rec.rcv_pay_div
                                       || '</p_rcv_pay_div_code>'
                       );
      -- �w�l�k�^�O�o�� �� �󕥋敪��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_name>'
                                       ||    lr_param_rec.rcv_pay_div_name
                                       || '</p_rcv_pay_div_name>'
                       );
      -- �w�l�k�^�O�o�� �� �i�ڋ敪
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_code>'
                                       ||    lr_param_rec.item_div
                                       || '</p_article_div_code>'
                       );
      -- �w�l�k�^�O�o�� �� �i�ڋ敪��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_name>'
                                       ||    lr_param_rec.item_div_name
                                       || '</p_article_div_name>'
                       );
      -- �w�l�k�^�O�o�� �� ���ѕ���
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_code>'
                                       ||    lr_param_rec.result_post
                                       || '</p_result_post_code>'
                       );
      -- �w�l�k�^�O�o�� �� ���ѕ�����
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_name>'
                                       ||    lr_param_rec.result_post_name
                                       || '</p_result_post_name>'
                       );
      -- �w�l�k�^�O�o�� �� �����N��(��)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_from>'
                                       ||    SUBSTRB(lr_param_rec.proc_from,1,4) || '�N'
                                       ||    SUBSTRB(lr_param_rec.proc_from,5,2) || '��'
                                       || '</p_trans_ym_from>'
                       );
      -- �w�l�k�^�O�o�� �� �����N��(��)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_to>'
                                       ||    SUBSTRB(lr_param_rec.proc_to,1,4) || '�N'
                                       ||    SUBSTRB(lr_param_rec.proc_to,5,2) || '��'
                                       || '</p_trans_ym_to>'
                       );
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </user_info>') ;
--
      -- ��data_info��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          <g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            <lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              <g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                <lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  <g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, ' <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  </g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                </lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              </g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            </lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          </g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        </lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>') ;
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
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
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  --   01 : �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : �����N��TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : �󕥋敪
     ,iv_prod_div        IN    VARCHAR2  --   04 : ���i�敪
     ,iv_item_div        IN    VARCHAR2  --   05 : �i�ڋ敪
     ,iv_result_post     IN    VARCHAR2  --   06 : ���ѕ���
     ,iv_whse_code       IN    VARCHAR2  --   07 : �q�ɃR�[�h
     ,iv_party_code      IN    VARCHAR2  --   08 : �o�א�R�[�h
     ,iv_crowd_type      IN    VARCHAR2  --   09 : �S���
     ,iv_crowd_code      IN    VARCHAR2  --   10 : �S�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : �o���Q�R�[�h
     ,iv_output_type     IN    VARCHAR2  --   12 : �o�͎��
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
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
    submain(
        iv_proc_from        => iv_proc_from         --   01 : �����N��FROM
       ,iv_proc_to          => iv_proc_to           --   02 : �����N��TO
       ,iv_rcv_pay_div      => iv_rcv_pay_div       --   03 : �󕥋敪
       ,iv_prod_div         => iv_prod_div          --   04 : ���i�敪
       ,iv_item_div         => iv_item_div          --   05 : �i�ڋ敪
       ,iv_result_post      => iv_result_post       --   06 : ���ѕ���
       ,iv_whse_code        => iv_whse_code         --   07 : �q�ɃR�[�h
       ,iv_party_code       => iv_party_code        --   08 : �o�א�R�[�h
       ,iv_crowd_type       => iv_crowd_type        --   09 : �S���
       ,iv_crowd_code       => iv_crowd_code        --   10 : �S�R�[�h
       ,iv_acnt_crowd_code  => iv_acnt_crowd_code   --   11 : �o���Q�R�[�h
       ,iv_output_type      => iv_output_type       --   12 : �o�͎��
       ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
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
END xxcmn770026c ;
/
