/*============================================================================
* �t�@�C���� : XxcsoInstallBasePvSumVOImpl
* �T�v����   : �������ėp������ʁ^������񌟍��r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-24 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ���������������邽�߂̃r���[�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvSumVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param whereStmt        ��������
   * @param orderBy          �\�[�g����
   *****************************************************************************
   */
  public void initQuery(
    String whereStmt
   ,String orderBy
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClause(whereStmt);
    setOrderByClause(orderBy);

    executeQuery();
  }
}