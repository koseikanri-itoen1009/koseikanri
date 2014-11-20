/*============================================================================
* �t�@�C���� : XxcsoEnableColumnSumVOImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^�g�p�\��r���[�I�u�W�F�N�g
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
 * �g�p�\����������邽�߂̃r���[�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEnableColumnSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEnableColumnSumVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param viewId        �r���[ID
   * @param pvDispMode    �ėp�����\�����[�h
   *****************************************************************************
   */
  public void initQuery(
    String viewId
   ,String pvDispMode
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);

    // SQL���s
    executeQuery();
  }

}