/*============================================================================
* �t�@�C���� : XxpoSupplierResultsMakeHdrVOImpl
* �T�v����   : �d����o�׎���:�o�^�w�b�_�[�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-12 1.0  �g������   �@�V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * �o�^�w�b�_�[�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsMakeHdrVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsMakeHdrVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchParams �����p�����[�^�pHashMap
   ****************************************************************************/
  public void initQuery(
    HashMap        searchParams         // �����L�[�p�����[�^
   )
  {

    // ������
    setWhereClauseParams(null);
    // �����p�����[�^(�w�b�_�[ID)
    String serchHeaderId = (String)searchParams.get("searchHeaderId");

    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, serchHeaderId);
  
    // SELECT�����s
    executeQuery();
  }
}