/*============================================================================
* �t�@�C���� : XxcsoPvExtractTermSumVOImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^��������(�V�K�쐬)�r���[�I�u�W�F�N�g
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
 * ��������(�V�K�쐬)���������邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvExtractTermSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvExtractTermSumVOImpl()
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

    executeQuery();
  }
}