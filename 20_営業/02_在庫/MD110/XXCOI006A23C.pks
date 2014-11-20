CREATE OR REPLACE PACKAGE XXCOI006A23C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A23C(spec)
 * Description      : VD�󕥏������ɁACSV�f�[�^���쐬���܂��B
 * MD.050           : VD��CSV�쐬<MD050_COI_006_A23>
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/10    1.0   H.Sasaki         ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
    iv_output_kbn       IN  VARCHAR2,       -- �y�K�{�z�o�͋敪
    iv_reception_date   IN  VARCHAR2,       -- �y�K�{�z�󕥔N��
    iv_cost_kbn         IN  VARCHAR2,       -- �y�K�{�z�����敪
    iv_base_code        IN  VARCHAR2        -- �y�C�Ӂz���_
  );
END XXCOI006A23C;
/
