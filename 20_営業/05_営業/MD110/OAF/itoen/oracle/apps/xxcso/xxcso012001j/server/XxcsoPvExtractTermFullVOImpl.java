/*============================================================================
* �t�@�C���� : XxcsoPvExtractTermFullVOImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^�ėp�������o������`�擾�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �ėp�������o������`�擾�r���[�s�I�u�W�F�N�g�r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvExtractTermFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvExtractTermFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param pvUseMode     �ėp�����g�p���[�h
   *****************************************************************************
   */
  public void initQuery(
    String pvUseMode
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, pvUseMode);
    setWhereClauseParam(idx++, pvUseMode);

  }

}