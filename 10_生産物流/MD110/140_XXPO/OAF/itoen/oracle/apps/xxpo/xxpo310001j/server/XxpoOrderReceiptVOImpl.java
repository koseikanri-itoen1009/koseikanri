/*============================================================================
* �t�@�C���� : XxpoOrderReceiptVOImpl
* �T�v����   : �������:�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  �g������     �V�K�쐬
* 2008-11-05 1.1  �ɓ��ЂƂ�   �����e�X�g�w�E103�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

/***************************************************************************
 * �����r���[�I�u�W�F�N�g�ł��B
 * @author  SCS �g�� ����
 * @version 1.1
 ***************************************************************************
 */
public class XxpoOrderReceiptVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderReceiptVOImpl()
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
    String headerNumber        = (String)searchParams.get("headerNumber");        // ����No.
    String requestNumber       = (String)searchParams.get("requestNumber");       // �x��No.
    String vendorCode          = (String)searchParams.get("vendorCode");          // �����R�[�h
    String vendorId            = (String)searchParams.get("vendorId");            // �����ID     
    String mediationCode       = (String)searchParams.get("mediationCode");       // �����҃R�[�h
    String mediationId         = (String)searchParams.get("mediationId");         // ������ID
    String deliveryDateFrom    = (String)searchParams.get("deliveryDateFrom");    // �[�i��(�J�n)
    String deliveryDateTo      = (String)searchParams.get("deliveryDateTo");      // �[�i��(�I��) 
    String status              = (String)searchParams.get("status");              // �X�e�[�^�X
    String location            = (String)searchParams.get("location");            // �[�i��R�[�h
    String department          = (String)searchParams.get("department");          // ���������R�[�h
    String approved            = (String)searchParams.get("approved");            // �����v
    String purchase            = (String)searchParams.get("purchase");            // �����敪
    String orderApproved       = (String)searchParams.get("orderApproved");       // ��������
    String purchaseApproved    = (String)searchParams.get("purchaseApproved");    // �d������
    String peopleCode          = (String)searchParams.get("PeopleCode");          // �]�ƈ��敪                                            // �������ID
  


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
// 2008-11-05 H.Itou Add Start �����e�X�g�w�E103
    // ����No�����͂���Ă��Ȃ��ꍇ�A���̑��̌���������ǉ�
    } else
    {
// 2008-11-05 H.Itou Add End �����e�X�g�w�E103
        
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
        
      // ����悪���͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(vendorId) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND vendor_id = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" vendor_id = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(vendorId);      
      }

      // �����҂����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(mediationId) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND mediation_id = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" mediation_id = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(mediationId);      
      }

      // �[����From�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(deliveryDateFrom) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND delivery_date >= :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" delivery_date >= :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(deliveryDateFrom);
      }

      // �[����To�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(deliveryDateTo) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND delivery_date <= :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" delivery_date <= :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(deliveryDateTo);      
      }

      // �X�e�[�^�X�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(status) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND status_code = :" + bindCount);
        // �����ǉ�1���ڂ̏ꍇ
        }else
        {
          whereClause.append(" status_code = :" + bindCount); 
        }
      
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(status);  
      }

      // �[���悪���͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(location) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND location_code = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" location_code = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(location);      
      }

      // �������������͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(department) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND department_code = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" department_code = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;     
        //�����l���Z�b�g
        parameters.add(department);      
      }

      // �����v�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(approved) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND approved_flag = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" approved_flag = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
      
        //�����l���Z�b�g
        parameters.add(approved);      
      }

      // �����敪�����͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(purchase) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND dropship_code = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" dropship_code = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;

        //�����l���Z�b�g
        parameters.add(purchase);      
      }

      // �������������͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(orderApproved) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND orderapproved_flag = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" orderapproved_flag = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
      
        //�����l���Z�b�g
        parameters.add(orderApproved);      
      }

      // �d�����������͂���Ă����ꍇ
      if (XxcmnUtility.isBlankOrNull(purchaseApproved) == false)
      {
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND purchaseapproved_flag = :" + bindCount);
      
        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" purchaseapproved_flag = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
      
        //�����l���Z�b�g
        parameters.add(purchaseApproved);      
      }
// 2008-11-05 H.Itou Add Start �����e�X�g�w�E103
    }
// 2008-11-05 H.Itou Add End �����e�X�g�w�E103
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