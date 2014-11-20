/*============================================================================
* �t�@�C���� : XxcsoPvDefFullVOImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^�ėp�����e�[�u���擾�r���[�N���X
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
 * ��ʃv���p�e�B���������邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvDefFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvDefFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param viewId     �r���[ID
   * @param isCopy     true:�V�K�쐬�A���� false:�X�V
   *****************************************************************************
   */
  public void initQuery(
    String viewId
   ,boolean isCopy
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    if ( isCopy )
    {
      setWhereClause("1=2");
    }
    int idx = 0;
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);

    // SQL���s
    executeQuery();
  }
}