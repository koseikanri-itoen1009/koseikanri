CREATE OR REPLACE PACKAGE XXINV550005C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550005C(spec)
 * Description      : �I���X�i�b�v�V���b�g�쐬
 * MD.050/070       : �݌�(���[)Draft2A (T_MD050_BPO_550)
 *                    �I���X�i�b�v�V���b�g�쐬Draft1A   (T_MD070_BPO_55E)
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
 *  2008/10/22    1.0  Oracle �勴�F�Y  �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2         --   �G���[���b�Z�[�W
   ,retcode              OUT    VARCHAR2         --   �G���[�R�[�h
   ,iv_invent_ym         IN     VARCHAR2         --   01. �Ώ۔N��	
   ,iv_whse_code1        IN     VARCHAR2         --   02. �q�ɃR�[�h�P
   ,iv_whse_code2        IN     VARCHAR2         --   03. �q�ɃR�[�h�Q
   ,iv_whse_code3        IN     VARCHAR2         --   04. �q�ɃR�[�h�R
   ,iv_whse_department1  IN     VARCHAR2         --   05. �q�ɊǗ������P
   ,iv_whse_department2  IN     VARCHAR2         --   06. �q�ɊǗ������Q
   ,iv_whse_department3  IN     VARCHAR2         --   07. �q�ɊǗ������R
   ,iv_block1            IN     VARCHAR2         --   08. �u���b�N�P
   ,iv_block2            IN     VARCHAR2         --   09. �u���b�N�Q
   ,iv_block3            IN     VARCHAR2         --   10. �u���b�N�R
   ,iv_arti_div_code     IN     VARCHAR2         --   11. ���i�敪
   ,iv_item_class_code   IN     VARCHAR2         --   12. �i�ڋ敪
  );
END XXINV550005C;
/
