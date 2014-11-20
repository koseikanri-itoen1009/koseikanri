/*============================================================================
* �t�@�C���� : XxcsoInstallBaseViewColumnVOImpl
* �T�v����   : �������ėp������ʁ^�\�������擾�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-23 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �\���������擾���邽�߂̃r���[�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseViewColumnVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseViewColumnVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����\�����[�h
   *****************************************************************************
   */
  public void initQuery(
    String  viewId
   ,String pvDisplayMode
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, pvDisplayMode);
    setWhereClauseParam(idx++, viewId);

    // SQL���s
    executeQuery();
  }

}