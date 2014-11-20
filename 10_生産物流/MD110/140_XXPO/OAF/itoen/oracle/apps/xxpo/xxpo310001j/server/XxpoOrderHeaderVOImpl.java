/*============================================================================
* �t�@�C���� : XxpoOrderHeaderVOImpl
* �T�v����   : ��������ڍ�:�����w�b�_�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-03 1.0  �g������     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

/***************************************************************************
 * �����w�b�_�r���[�I�u�W�F�N�g�ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderHeaderVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchParams �����p�����[�^�pHashMap
   ****************************************************************************/
  public void initQuery(
    HashMap searchParams         // �����L�[�p�����[�^
   )
  {

    StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
    ArrayList parameters = new ArrayList();             // �o�C���h�ϐ��ݒ�l
    int bindCount = 0;                                  // �o�C���h�ϐ��J�E���g

    // ������
    setWhereClauseParams(null);

    // ���������擾
    String headerNumber        = (String)searchParams.get("HeaderNumber");        // ����No.
    String requestNumber       = (String)searchParams.get("RequestNumber");       // �x��No.

    // *************************** //
    // *        �����쐬         * //
    // *************************** //
    // ����No.�����͂���Ă����ꍇ
    if (XxcmnUtility.isBlankOrNull(headerNumber) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND header_number = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" header_number = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(headerNumber);
    }
        
    // �x��No.�����͂���Ă����ꍇ
    if (XxcmnUtility.isBlankOrNull(requestNumber) == false)
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND request_number = :" + bindCount);
      
      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" request_number = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(requestNumber);
    }


    // ����������VO�ɃZ�b�g
    setWhereClause(whereClause.toString());

    // �o�C���h�l���ݒ肳��Ă����ꍇ
    if (bindCount > 0)
    {
      // �����l�z����擾
      Object[] params = new Object[bindCount];
      params = parameters.toArray();
      // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
      setWhereClauseParams(params);
    }
    
    executeQuery();
  }
}