/*============================================================================
* �t�@�C���� : XxcsoPvDefUpdDfltFlgVOImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^�f�t�H���g�t���O�ݒ�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �f�t�H���g�t���O�������^�ݒ肷�邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvDefUpdDfltFlgVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvDefUpdDfltFlgVOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param viewId     �r���[ID
   *****************************************************************************
   */
  public void initQuery(
    String viewId
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);

    // SQL���s
    executeQuery();
  }

}